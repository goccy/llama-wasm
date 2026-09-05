package asm

import (
	"strings"
	"testing"
)

func TestMXFP4_8x8KernelShape(t *testing.T) {
	g := a64GemvMXFP4_8x8Kernel("FnGvdotprod", NewConstPool("t_"), true)
	for _, want := range []string{"gvxgroup:", "gvxblk:", "ldur q25, [x12, #64]", "ushll v15.8h, v15.8b", "ushl v22.4s, v22.4s, v15.4s", "cmhs v15.4s, v15.4s, v21.4s", "bsl v15.16b, v23.16b, v22.16b", "ldur q8, [x9, #8]"} {
		if !strings.Contains(g, want) {
			t.Errorf("a64 mxfp4 gemv missing %q", want)
		}
	}
	if strings.Contains(g, "fcvtl v15.4s, v15.4h") {
		t.Errorf("a64 mxfp4 gemv widens f16 scales")
	}
	m := a64GemmMXFP4_8x8Kernel("FnGmi8mm", NewConstPool("t_"), true)
	for _, want := range []string{"gmxblk:", "smmla v0.4s", "ushll v8.8h, v8.8b", "bsl v9.16b, v27.16b, v26.16b"} {
		if !strings.Contains(m, want) {
			t.Errorf("a64 mxfp4 gemm missing %q", want)
		}
	}
	x := x64GemvMXFP4_8x8Kernel("FnGvavx2", NewConstPool("t_"), true)
	for _, want := range []string{"VPMOVZXBD\t(R9), Y14", "VPSLLVD\tY14, Y5, Y5", "VBLENDVPS\tY6, Y4, Y5, Y14", "VPSIGNB\tY5, Y8, Y10"} {
		if !strings.Contains(x, want) {
			t.Errorf("x64 mxfp4 gemv missing %q", want)
		}
	}
	if strings.Contains(x, "VCVTPH2PS\t(R9), Y14") {
		t.Errorf("x64 mxfp4 gemv converts f16 scales")
	}
	xm := x64GemmMXFP4_8x8Kernel("FnGmavx2", NewConstPool("t_"), true)
	for _, want := range []string{"VPMOVZXBD\t(R9), Y15", "VBLENDVPS\tY14, Y8, Y9, Y15"} {
		if !strings.Contains(xm, want) {
			t.Errorf("x64 mxfp4 gemm missing %q", want)
		}
	}
}

// mxfp4x8RunSrc: mxfp4 rows (17-byte blocks: E8M0 scale, 16 nibble bytes
// indexing kvalues_fp4), their block_mxfp4x8 repack, GEMV/GEMM runners.
const mxfp4x8RunSrc = `
func genMXFP4Row(s *lcg, nb int) ([]byte, []float64) {
	x := make([]byte, 17*nb)
	v := make([]float64, 32*nb)
	for b := 0; b < nb; b++ {
		e := byte(118 + s.next()%20)
		if b%5 == 2 {
			e = byte(s.next() % 3)
		}
		x[17*b] = e
		dv := math.Ldexp(1, int(e)-128)
		for j := 0; j < 16; j++ {
			q0 := int(s.next() % 16)
			q1 := int(s.next() % 16)
			x[17*b+1+j] = byte(q0) | byte(q1)<<4
			v[32*b+j] = float64(kvaluesFP4[q0]) * dv
			v[32*b+j+16] = float64(kvaluesFP4[q1]) * dv
		}
	}
	return x, v
}

// repackMXFP4x8: llama.cpp's make_block_mxfp4x8 — eight E8M0 scales then
// the rows' 8-byte groups interleaved.
func repackMXFP4x8(rows [8][]byte, nb int) []byte {
	out := make([]byte, 136*nb)
	for b := 0; b < nb; b++ {
		o := out[136*b:]
		for c := 0; c < 8; c++ {
			o[c] = rows[c][17*b]
		}
		for i := 0; i < 16; i++ {
			copy(o[8+8*i:8+8*i+8], rows[i%8][17*b+1+(i/8)*8:17*b+1+(i/8)*8+8])
		}
	}
	return out
}

func runGemvMX(t *testing.T, kernel q5Kernel, n, nc int, seed uint32) {
	t.Helper()
	nb := n / 32
	s := lcg(seed)
	y, yv := genQ8Row(&s, nb)
	var rows [][]float64
	var vx []byte
	for g := 0; g < nc/8; g++ {
		var eight [8][]byte
		for j := 0; j < 8; j++ {
			x, xv := genMXFP4Row(&s, nb)
			eight[j] = x
			rows = append(rows, xv)
		}
		vx = append(vx, repackMXFP4x8(eight, nb)...)
	}
	sOff, xOff := 256, 1024
	yOff := xOff + len(vx) + 64
	mem := make([]byte, yOff+len(y)+256)
	copy(mem[xOff:], vx)
	copy(mem[yOff:], y)
	memSize := uint64(len(mem))
	m := &mockModule{memSizePtr: &memSize, mem: unsafe.Pointer(&mem[0])}
	kernel(m, int32(n), int64(sOff), int64(nc), int64(xOff), int64(yOff), 1, int32(nc))
	for c := 0; c < nc; c++ {
		want, mag := dotRows(rows[c], yv)
		if got := get32(mem, sOff+4*c); !closeQ5(got, want, mag) {
			t.Fatalf("gemv mxfp4 n=%d nc=%d col %d = %v, want %v", n, nc, c, got, want)
		}
	}
}

func runGemmMX(t *testing.T, kernel q5Kernel, n, nr, nc int, seed uint32) {
	t.Helper()
	nb := n / 32
	s := lcg(seed)
	var rows [][]float64
	var vx []byte
	for g := 0; g < nc/8; g++ {
		var eight [8][]byte
		for j := 0; j < 8; j++ {
			x, xv := genMXFP4Row(&s, nb)
			eight[j] = x
			rows = append(rows, xv)
		}
		vx = append(vx, repackMXFP4x8(eight, nb)...)
	}
	var yvs [][]float64
	var vy []byte
	for g := 0; g < nr/4; g++ {
		var four [4][]byte
		for r := 0; r < 4; r++ {
			y, yv := genQ8Row(&s, nb)
			four[r] = y
			yvs = append(yvs, yv)
		}
		vy = append(vy, packQ8_0x4(four, nb)...)
	}
	bs := nc + 8
	sOff, xOff := 256, 256+nr*bs*4+64
	yOff := xOff + len(vx) + 64
	mem := make([]byte, yOff+len(vy)+256)
	copy(mem[xOff:], vx)
	copy(mem[yOff:], vy)
	memSize := uint64(len(mem))
	m := &mockModule{memSizePtr: &memSize, mem: unsafe.Pointer(&mem[0])}
	kernel(m, int32(n), int64(sOff), int64(bs), int64(xOff), int64(yOff), int32(nr), int32(nc))
	for r := 0; r < nr; r++ {
		for c := 0; c < nc; c++ {
			want, mag := dotRows(rows[c], yvs[r])
			if got := get32(mem, sOff+4*(r*bs+c)); !closeQ5(got, want, mag) {
				t.Fatalf("gemm mxfp4 n=%d nr=%d nc=%d [%d][%d] = %v, want %v", n, nr, nc, r, c, got, want)
			}
		}
	}
}
`

const mxfp4x8RunTest = `package quantrun

import "testing"

func TestGemvMX(t *testing.T) {
	seed := uint32(19)
	for _, n := range []int{32, 64, 256, 896} {
		for _, nc := range []int{8, 16, 24} {
			seed++
			runGemvMX(t, GemvKernel, n, nc, seed)
		}
	}
}

func TestGemmMX(t *testing.T) {
	seed := uint32(43)
	for _, n := range []int{32, 64, 256, 896} {
		for _, nr := range []int{4, 8} {
			for _, nc := range []int{8, 16, 24} {
				seed++
				runGemmMX(t, GemmKernel, n, nr, nc, seed)
			}
		}
	}
}

func TestExactMX(t *testing.T) {
	for _, n := range []int{32, 256, 896} {
		for _, nc := range []int{8, 24} {
			runX8Exact(t, "mxfp4", GemvKernel, GemmKernel, n, nc, uint32(n+nc), genMXFP4Row, repackMXFP4x8)
		}
	}
}
`

func TestA64MXFP4_8x8KernelGate(t *testing.T) {
	_, argBytes := repackGemmArgs(true)
	pool := NewConstPool("mx8_")
	asm := wrap("arm64", "GemvKernel", 16, argBytes, "dotprod", a64GemvMXFP4_8x8Kernel("GemvKernel", pool, true)) +
		wrap("arm64", "GemmKernel", a64GemmQ5Frame, argBytes, "i8mm", a64GemmMXFP4_8x8Kernel("GemmKernel", pool, true)) + pool.Emit()
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "arm64", asm, quantRunCommon+q5x8RunSrc+q4x8RunSrc+mxfp4RunSrc+mxfp4x8RunSrc+q5x8Decls, mxfp4x8RunTest)
	runArm64Gate(t, dir, ".", "TestGem[vm]MX|TestExactMX", asm)
}

func TestX64MXFP4_8x8KernelGate(t *testing.T) {
	_, argBytes := repackGemmArgs(true)
	pool := NewConstPool("mx8x_")
	asm := wrap("amd64", "GemvKernel", 16, argBytes, "avx2", x64GemvMXFP4_8x8Kernel("GemvKernel", pool, true)) +
		wrap("amd64", "GemmKernel", x64GemmQ5Frame, argBytes, "avx2", x64GemmMXFP4_8x8Kernel("GemmKernel", pool, true)) + pool.Emit()
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "amd64", asm, quantRunCommon+q5x8RunSrc+q4x8RunSrc+mxfp4RunSrc+mxfp4x8RunSrc+q5x8Decls, mxfp4x8RunTest)
	runAmd64Gate(t, dir, ".", "TestGem[vm]MX|TestExactMX", asm)
}
