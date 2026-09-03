package asm

import (
	"strings"
	"testing"
)

// The retarget fires only under FastMath without the opt-out, and
// only when the module exports the repack GEMM by its debug name.
func TestRepackGemmKernelShape(t *testing.T) {
	a := a64RepackGemmKernel("Fn9dotprod", "i8mm", true)
	for _, want := range []string{
		"smmla v7.4s, v23.16b, v19.16b", "zip1 v18.4s, v16.4s, v17.4s",
		"dup v19.2d, v16.d[1]", "gemmmpre:", "gemmmchunk:",
		"sdot v24.4s, v0.16b, v1.4b[0]",
		"sdot v27.4s, v0.16b, v1.4b[3]",
		"fmul v27.4s, v27.4s, v2.4s",
		"fmla v31.4s, v27.4s, v3.s[3]",
		"fcvtl v2.4s, v2.4h",
		"gemmblk:", "gemmoob:",
	} {
		if !strings.Contains(a, want) {
			t.Errorf("a64 kernel missing %q", want)
		}
	}
	pool := &ConstPool{}
	x := x64RepackGemmKernel("Fn9avx2", "avx512vnni", pool, true)
	for _, want := range []string{
		"VPDPBUSD", "VPMADDWD", "VPHADDD", "VCVTPH2PS", "VADDPS",
		"VPBROADCASTQ", "VPERM2I128", "VPERMPS", "gemmpre:", "gemmchunk:",
		"vgemmblk:", "gemmblk:", "VZEROUPPER",
	} {
		if !strings.Contains(x, want) {
			t.Errorf("x64 kernel missing %q", want)
		}
	}
}

// repackGemmRunSrc is the shared execution driver: builds a q8_0x4
// problem in a mock module memory, runs the kernel, and compares
// against a scalar reference (float64 accumulation, small relative
// tolerance — the kernel fuses mul+add).
const repackGemmRunSrc = `package gemmrun

import (
	"math"
	"os"
	"os/exec"
	"runtime"
	"strings"
	"testing"
	"unsafe"
)

// hostHasI8MM reports FEAT_I8MM on the executing arm64 host.
func hostHasI8MM() bool {
	switch runtime.GOOS {
	case "linux":
		data, err := os.ReadFile("/proc/cpuinfo")
		return err == nil && strings.Contains(string(data), " i8mm")
	case "darwin":
		out, err := exec.Command("sysctl", "-n", "hw.optional.arm.FEAT_I8MM").Output()
		return err == nil && strings.TrimSpace(string(out)) == "1"
	}
	return false
}

type mockModule struct {
	memSizePtr *uint64
	mem        unsafe.Pointer
}

func f16bits(f float32) uint16 {
	b := math.Float32bits(f)
	sign := uint16(b>>16) & 0x8000
	exp := int32(b>>23&0xFF) - 127 + 15
	man := b >> 13 & 0x3FF
	if exp <= 0 || exp >= 31 {
		return sign | 0x3C00 // clamp to 1.0 for test data
	}
	return sign | uint16(exp)<<10 | uint16(man)
}

func f16val(h uint16) float64 {
	sign := float64(1)
	if h&0x8000 != 0 {
		sign = -1
	}
	exp := int32(h >> 10 & 0x1F)
	man := float64(h & 0x3FF)
	if exp == 0 {
		return sign * man / 1024 * math.Pow(2, -14)
	}
	return sign * (1 + man/1024) * math.Pow(2, float64(exp-15))
}

const (
	nr = 12 // three row groups: one SMMLA pair + the SDOT tail group
	nc = 8
	bs = 10 // output row stride in floats (> nc to catch stride bugs)
)

func buildProblem(mem []byte, n, sOff, vxOff, vyOff int) {
	nb := n / 32
	rng := uint32(0x12345)
	nextI8 := func() int8 {
		rng = rng*1664525 + 1013904223
		return int8(int32(rng>>24)%255 - 127)
	}
	fill := func(off, groups int) {
		for g := 0; g < groups; g++ {
			base := off + g*136
			for j := 0; j < 4; j++ {
				h := f16bits(1.0 + float32(g%3)*0.5 + float32(j)*0.25)
				mem[base+2*j] = byte(h)
				mem[base+2*j+1] = byte(h >> 8)
			}
			for i := 0; i < 128; i++ {
				mem[base+8+i] = byte(nextI8())
			}
		}
	}
	fill(vxOff, (nc/4)*nb)
	fill(vyOff, (nr/4)*nb)
	_ = sOff
}

func reference(mem []byte, n, vxOff, vyOff int) [nr][nc]float64 {
	nb := n / 32
	var out [nr][nc]float64
	for y := 0; y < nr/4; y++ {
		for x := 0; x < nc/4; x++ {
			for l := 0; l < nb; l++ {
				a := vyOff + (y*nb+l)*136
				bq := vxOff + (x*nb+l)*136
				for row := 0; row < 4; row++ {
					da := f16val(uint16(mem[a+2*row]) | uint16(mem[a+2*row+1])<<8)
					for col := 0; col < 4; col++ {
						db := f16val(uint16(mem[bq+2*col]) | uint16(mem[bq+2*col+1])<<8)
						sumi := 0
						for k := 0; k < 8; k++ {
							for i := 0; i < 4; i++ {
								w := int8(mem[bq+8+k*16+col*4+i])
								av := int8(mem[a+8+k*16+row*4+i])
								sumi += int(w) * int(av)
							}
						}
						out[y*4+row][x*4+col] += float64(sumi) * da * db
					}
				}
			}
		}
	}
	return out
}

// runOne exercises the kernel on an n-column problem: n = 64 is the
// two-block shape, n = 32*300 spans more blocks than the amd64
// nest's per-chunk scratch holds, so it covers the chunk boundary and
// the accumulate-into-s reload path.
func runOne(t *testing.T, kernel func(m *mockModule, l0 int32, l1, l2, l3, l4 int64, l5, l6 int32), n int) {
	nb := n / 32
	sOff := 256
	vxOff := 8192
	vyOff := vxOff + (nc/4)*nb*136 + 64
	mem := make([]byte, vyOff+(nr/4)*nb*136+4096)
	buildProblem(mem, n, sOff, vxOff, vyOff)
	memSize := uint64(len(mem))
	m := &mockModule{memSizePtr: &memSize, mem: unsafe.Pointer(&mem[0])}
	kernel(m, int32(n), int64(sOff), int64(bs), int64(vxOff), int64(vyOff), nr, nc)
	want := reference(mem, n, vxOff, vyOff)
	for r := 0; r < nr; r++ {
		for c := 0; c < nc; c++ {
			bits := uint32(mem[sOff+(r*bs+c)*4]) | uint32(mem[sOff+(r*bs+c)*4+1])<<8 |
				uint32(mem[sOff+(r*bs+c)*4+2])<<16 | uint32(mem[sOff+(r*bs+c)*4+3])<<24
			got := float64(math.Float32frombits(bits))
			w := want[r][c]
			if diff := math.Abs(got - w); diff > 1e-3+1e-4*math.Abs(w) {
				t.Fatalf("s[%d][%d] = %v, want %v", r, c, got, w)
			}
		}
	}
}
`

// TestA64RepackGemmKernelGate assembles and links the arm64 kernel on
// every host, and executes the numeric comparison on arm64 hosts
// (the CI arm64 runner has FEAT_DotProd).
func TestA64RepackGemmKernelGate(t *testing.T) {
	_, argBytes := repackGemmArgs(true)
	kernel := wrap("arm64", "GemmKernel", a64RepackGemmFrame, argBytes, "dotprod", a64RepackGemmKernel("GemmKernel", "dotprod", true)) +
		wrap("arm64", "GemmKernelSMMLA", a64RepackGemmFrame, argBytes, "i8mm", a64RepackGemmKernel("GemmKernelSMMLA", "i8mm", true))
	dir := t.TempDir()
	writeRunTree(t, dir, "gemmrun", "arm64", kernel, repackGemmRunSrc+
		"\nfunc GemmKernel(m *mockModule, l0 int32, l1, l2, l3, l4 int64, l5, l6 int32)\nfunc GemmKernelSMMLA(m *mockModule, l0 int32, l1, l2, l3, l4 int64, l5, l6 int32)\nfunc trapstub()\n\nvar _ = trapstub\n",
		`package gemmrun

import "testing"

// The SDOT body, then the SMMLA body (row-group pairs with the SDOT
// tail for the odd group) when the host has FEAT_I8MM.
func TestGemmA64(t *testing.T) {
	runOne(t, GemmKernel, 64)
	runOne(t, GemmKernel, 32*300)
}

func TestGemmA64SMMLA(t *testing.T) {
	if !hostHasI8MM() {
		t.Skip("host has no FEAT_I8MM")
	}
	runOne(t, GemmKernelSMMLA, 64)
	runOne(t, GemmKernelSMMLA, 32*300)
}
`)
	runArm64Gate(t, dir, ".", "TestGemmA64", kernel)
}

// TestX64RepackGemmKernelGate assembles and links the amd64 kernel on
// every host and executes the numeric comparison when the host has
// AVX2 (both dispatch arms when it also has VNNI).
func TestX64RepackGemmKernelGate(t *testing.T) {
	_, argBytes := repackGemmArgs(true)
	pool := &ConstPool{}
	kernel := wrap("amd64", "GemmKernel", x64RepackGemmFrame, argBytes, "avx2", x64RepackGemmKernel("GemmKernel", "avx2", pool, true)) +
		wrap("amd64", "GemmKernelVNNI", x64RepackGemmFrame, argBytes, "avx512vnni", x64RepackGemmKernel("GemmKernelVNNI", "avx512vnni", pool, true)) +
		pool.Emit()
	dir := t.TempDir()
	writeRunTree(t, dir, "gemmrun", "amd64", kernel, repackGemmRunSrc+
		"\nfunc GemmKernel(m *mockModule, l0 int32, l1, l2, l3, l4 int64, l5, l6 int32)\nfunc GemmKernelVNNI(m *mockModule, l0 int32, l1, l2, l3, l4 int64, l5, l6 int32)\nfunc trapstub()\n\nvar _ = trapstub\n",
		`package gemmrun

import "testing"

func TestGemmX64(t *testing.T) {
	runOne(t, GemmKernel, 64)
	runOne(t, GemmKernel, 32*300)
}

func TestGemmX64VNNI(t *testing.T) {
	runOne(t, GemmKernelVNNI, 64)
	runOne(t, GemmKernelVNNI, 32*300)
}
`)
	runName := "TestGemmX64$"
	if hostHasVNNI(t) {
		runName = "TestGemmX64"
	}
	runAmd64Gate(t, dir, ".", runName, kernel)
}
