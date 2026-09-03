package asm

import (
	"strings"
	"testing"
)

func TestRepackGemvKernelShape(t *testing.T) {
	a := a64RepackGemvKernel("Fn9dotprod", true)
	for _, want := range []string{"sdot v27.4s, v3.16b, v17.4b[3]", "gv4blk:", "gv1blk:", "fcvt s18, h18"} {
		if !strings.Contains(a, want) {
			t.Errorf("a64 gemv missing %q", want)
		}
	}
	pool := &ConstPool{}
	x := x64RepackGemvKernel("Fn9avx2", "avx512vnni", pool, true)
	for _, want := range []string{"VPMADDWD", "VPDPBUSD", "VPBROADCASTQ", "VBROADCASTI128", "VINSERTI128", "gvg4blk:", "vgvg4blk:", "gvg1blk:", "VZEROUPPER"} {
		if !strings.Contains(x, want) {
			t.Errorf("x64 gemv missing %q", want)
		}
	}
}

// repackGemvRunSrc: one activation row (block_q8_0) against nc columns
// of block_q8_0x4 weights, compared with a float64 reference per
// column (small relative tolerance: the kernel fuses nothing but the
// f32 sums run in block order like the reference, so this is tight).
const repackGemvRunSrc = `package gemvrun

import (
	"math"
	"testing"
	"unsafe"
)

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
		return sign | 0x3C00
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

func runGemv(t *testing.T, kernel func(m *mockModule, l0 int32, l1, l2, l3, l4 int64, l5, l6 int32), n, nc int) {
	t.Helper()
	nb := n / 32
	sOff := 256
	vyOff := 4096
	vxOff := vyOff + nb*34 + 64
	mem := make([]byte, vxOff+(nc/4)*nb*136+4096)
	rng := uint32(0xBEEF) + uint32(n*31+nc)
	nextI8 := func() int8 {
		rng = rng*1664525 + 1013904223
		return int8(int32(rng>>24)%255 - 127)
	}
	// activation row: nb blocks of [d f16][32 x i8]
	for l := 0; l < nb; l++ {
		base := vyOff + l*34
		h := f16bits(0.75 + float32(l%5)*0.125)
		mem[base], mem[base+1] = byte(h), byte(h>>8)
		for i := 0; i < 32; i++ {
			mem[base+2+i] = byte(nextI8())
		}
	}
	// weights: (nc/4) groups x nb blocks of [4 x d f16][128 x i8]
	for g := 0; g < (nc/4)*nb; g++ {
		base := vxOff + g*136
		for j := 0; j < 4; j++ {
			h := f16bits(1.0 + float32(g%3)*0.5 + float32(j)*0.25)
			mem[base+2*j], mem[base+2*j+1] = byte(h), byte(h>>8)
		}
		for i := 0; i < 128; i++ {
			mem[base+8+i] = byte(nextI8())
		}
	}
	memSize := uint64(len(mem))
	m := &mockModule{memSizePtr: &memSize, mem: unsafe.Pointer(&mem[0])}
	kernel(m, int32(n), int64(sOff), 0, int64(vxOff), int64(vyOff), 1, int32(nc))
	for x := 0; x < nc/4; x++ {
		for col := 0; col < 4; col++ {
			var want float64
			for l := 0; l < nb; l++ {
				a := vyOff + l*34
				bq := vxOff + (x*nb+l)*136
				da := f16val(uint16(mem[a]) | uint16(mem[a+1])<<8)
				db := f16val(uint16(mem[bq+2*col]) | uint16(mem[bq+2*col+1])<<8)
				sumi := 0
				for k := 0; k < 8; k++ {
					for i := 0; i < 4; i++ {
						sumi += int(int8(mem[bq+8+k*16+col*4+i])) * int(int8(mem[a+2+k*4+i]))
					}
				}
				want += float64(sumi) * da * db
			}
			off := sOff + (x*4+col)*4
			got := float64(math.Float32frombits(uint32(mem[off]) | uint32(mem[off+1])<<8 | uint32(mem[off+2])<<16 | uint32(mem[off+3])<<24))
			if math.Abs(got-want) > 1e-3+1e-4*math.Abs(want) {
				t.Fatalf("n=%d nc=%d s[%d] = %v, want %v", n, nc, x*4+col, got, want)
			}
		}
	}
	for off := sOff + nc*4; off < vyOff; off++ {
		if mem[off] != 0 {
			t.Fatalf("n=%d nc=%d byte %d past s written", n, nc, off)
		}
	}
}
`

const repackGemvRunTest = `package gemvrun

import "testing"

func TestGemv(t *testing.T) {
	for _, c := range [][2]int{{64, 16}, {64, 20}, {32, 4}, {96, 28}, {32 * 600, 8}, {32 * 513, 4}} {
		runGemv(t, GemvKernel, c[0], c[1])
	}
}
`

func TestA64RepackGemvKernelGate(t *testing.T) {
	_, argBytes := repackGemmArgs(true)
	kernel := wrap("arm64", "GemvKernel", 16, argBytes, "dotprod", a64RepackGemvKernel("GemvKernel", true))
	dir := t.TempDir()
	writeRunTree(t, dir, "gemvrun", "arm64", kernel, repackGemvRunSrc+
		"\nfunc GemvKernel(m *mockModule, l0 int32, l1, l2, l3, l4 int64, l5, l6 int32)\nfunc trapstub()\n\nvar _ = trapstub\n",
		repackGemvRunTest)
	runArm64Gate(t, dir, ".", "TestGemv", kernel)
}

func TestX64RepackGemvKernelGate(t *testing.T) {
	_, argBytes := repackGemmArgs(true)
	pool := &ConstPool{}
	kernel := wrap("amd64", "GemvKernel", x64RepackGemvFrame, argBytes, "avx2", x64RepackGemvKernel("GemvKernel", "avx2", pool, true)) +
		wrap("amd64", "GemvKernelVNNI", x64RepackGemvFrame, argBytes, "avx512vnni", x64RepackGemvKernel("GemvKernelVNNI", "avx512vnni", pool, true)) +
		pool.Emit()
	dir := t.TempDir()
	writeRunTree(t, dir, "gemvrun", "amd64", kernel, repackGemvRunSrc+
		"\nfunc GemvKernel(m *mockModule, l0 int32, l1, l2, l3, l4 int64, l5, l6 int32)\nfunc GemvKernelVNNI(m *mockModule, l0 int32, l1, l2, l3, l4 int64, l5, l6 int32)\nfunc trapstub()\n\nvar _ = trapstub\n",
		`package gemvrun

import "testing"

func TestGemvX64(t *testing.T) {
	for _, c := range [][2]int{{64, 16}, {64, 20}, {32, 4}, {96, 28}, {32 * 600, 8}, {32 * 513, 4}} {
		runGemv(t, GemvKernel, c[0], c[1])
	}
}

func TestGemvX64VNNI(t *testing.T) {
	for _, c := range [][2]int{{64, 16}, {64, 20}, {32, 4}, {96, 28}, {32 * 600, 8}, {32 * 513, 4}} {
		runGemv(t, GemvKernelVNNI, c[0], c[1])
	}
}
`)
	runName := "TestGemvX64$"
	if hostHasVNNI(t) {
		runName = "TestGemvX64"
	}
	runAmd64Gate(t, dir, ".", runName, kernel)
}
