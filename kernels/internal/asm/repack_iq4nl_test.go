package asm

import (
	"strings"
	"testing"
)

func TestIQ4NL8x8KernelShape(t *testing.T) {
	pool := NewConstPool("t_")
	a := a64GemvIQ4NL8x8Kernel("FnGvdotprod", pool, true)
	for _, want := range []string{"gvigroup:", "gviblk:", "tbl v9.16b", "tbl v10.16b", "ldur q25, [x12, #48]"} {
		if !strings.Contains(a, want) {
			t.Errorf("a64 iq4_nl gemv missing %q", want)
		}
	}
	if strings.Contains(a, "sub v0.4s, v0.4s, v22.4s") {
		t.Errorf("a64 iq4_nl gemv still subtracts a quant offset")
	}
	g := a64GemmIQ4NL8x8Kernel("FnGmi8mm", pool, true)
	for _, want := range []string{"gmirows:", "gmiblk:", "qiscratch", "tbl v9.16b", "smmla v0.4s"} {
		if !strings.Contains(g, want) {
			t.Errorf("a64 iq4_nl gemm missing %q", want)
		}
	}
	x := x64GemvIQ4NL8x8Kernel("FnGvavx2", NewConstPool("t_"), true)
	if strings.Contains(x, "VPSUBD") {
		t.Errorf("x64 iq4_nl gemv folds a quant offset: the signed table has none")
	}
	for _, want := range []string{"groupi:", "VPSHUFB\tY5, Y12, Y5", "VPSHUFB\tY6, Y12, Y6", "VPSIGNB\tY5, Y8, Y10", "VPSIGNB\tY5, Y5, Y5", "VPMADDUBSW\tY10, Y5, Y10"} {
		if !strings.Contains(x, want) {
			t.Errorf("x64 iq4_nl gemv missing %q", want)
		}
	}
	xm := x64GemmIQ4NL8x8Kernel("FnGmavx2", NewConstPool("t_"), true)
	for _, want := range []string{"rowsi:", "VPSHUFB\tY9, Y11, Y9", "VPSIGNB\tY9, Y9, Y11", "VPSIGNB\tY9, Y12, Y13", "VPMADDUBSW\tY13, Y11, Y13", "VPXOR\tY8, Y8, Y8"} {
		if !strings.Contains(xm, want) {
			t.Errorf("x64 iq4_nl gemm missing %q", want)
		}
	}
	c := q5x8Consts()
	if len(c) != 64 || int8(c[48]) != -127 || int8(c[63]) != 113 {
		t.Errorf("q5x8 const blob: kvalues table")
	}
	xc := x64Q5Consts()
	if len(xc) != 320 || int8(xc[256]) != -127 || int8(xc[256+15]) != 113 || int8(xc[256+16]) != -127 || xc[288] != 0x88 {
		t.Errorf("x64 q5 const blob: signed kvalues table")
	}
}

// iq4x8RunSrc: IQ4_NL rows (18-byte blocks, nibbles indexing kvalues)
// and the GEMV/GEMM runners over the q4_0x8 repack layout (identical
// byte layout); q8 rows, packing, dotRows and closeQ5 come from
// q5x8RunSrc, repackQ4_0x8 from q4x8RunSrc.
const iq4x8RunSrc = `
var kvaluesIQ4NL = [16]int8{-127, -104, -83, -65, -49, -35, -22, -10, 1, 13, 25, 38, 53, 69, 89, 113}

func genIQ4Row(s *lcg, nb int) ([]byte, []float64) {
	x := make([]byte, 18*nb)
	v := make([]float64, 32*nb)
	for b := 0; b < nb; b++ {
		d := s.scale()
		put16(x, 18*b, f16bits(d))
		dv := f16val(f16bits(d))
		for j := 0; j < 16; j++ {
			q0 := int(s.next() % 16)
			q1 := int(s.next() % 16)
			x[18*b+2+j] = byte(q0) | byte(q1)<<4
			v[32*b+j] = float64(kvaluesIQ4NL[q0]) * dv
			v[32*b+j+16] = float64(kvaluesIQ4NL[q1]) * dv
		}
	}
	return x, v
}

func runGemvIQ4(t *testing.T, kernel q5Kernel, n, nc int, seed uint32) {
	t.Helper()
	nb := n / 32
	s := lcg(seed)
	y, yv := genQ8Row(&s, nb)
	var rows [][]float64
	var vx []byte
	for g := 0; g < nc/8; g++ {
		var eight [8][]byte
		for j := 0; j < 8; j++ {
			x, xv := genIQ4Row(&s, nb)
			eight[j] = x
			rows = append(rows, xv)
		}
		vx = append(vx, repackX8Plain(eight, nb)...)
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
			t.Fatalf("gemv iq4_nl n=%d nc=%d col %d = %v, want %v", n, nc, c, got, want)
		}
	}
}

func runGemmIQ4(t *testing.T, kernel q5Kernel, n, nr, nc int, seed uint32) {
	t.Helper()
	nb := n / 32
	s := lcg(seed)
	var rows [][]float64
	var vx []byte
	for g := 0; g < nc/8; g++ {
		var eight [8][]byte
		for j := 0; j < 8; j++ {
			x, xv := genIQ4Row(&s, nb)
			eight[j] = x
			rows = append(rows, xv)
		}
		vx = append(vx, repackX8Plain(eight, nb)...)
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
				t.Fatalf("gemm iq4_nl n=%d nr=%d nc=%d [%d][%d] = %v, want %v", n, nr, nc, r, c, got, want)
			}
		}
	}
}
`

const iq4x8RunTest = `package quantrun

import "testing"

func TestGemvIQ4(t *testing.T) {
	seed := uint32(17)
	for _, n := range []int{32, 64, 256, 896} {
		for _, nc := range []int{8, 16, 24} {
			seed++
			runGemvIQ4(t, GemvKernel, n, nc, seed)
		}
	}
}

func TestGemmIQ4(t *testing.T) {
	seed := uint32(41)
	for _, n := range []int{32, 64, 256, 896} {
		for _, nr := range []int{4, 8} {
			for _, nc := range []int{8, 16, 24} {
				seed++
				runGemmIQ4(t, GemmKernel, n, nr, nc, seed)
			}
		}
	}
}

func TestExactIQ4(t *testing.T) {
	for _, n := range []int{32, 256, 896} {
		for _, nc := range []int{8, 24} {
			runX8Exact(t, "iq4_nl", GemvKernel, GemmKernel, n, nc, uint32(n+nc), genIQ4Row, repackX8Plain)
		}
	}
}
`

func TestA64IQ4NL8x8KernelGate(t *testing.T) {
	_, argBytes := repackGemmArgs(true)
	pool := NewConstPool("iq4_")
	asm := wrap("arm64", "GemvKernel", 16, argBytes, "dotprod", a64GemvIQ4NL8x8Kernel("GemvKernel", pool, true)) +
		wrap("arm64", "GemmKernel", a64GemmQ5Frame, argBytes, "i8mm", a64GemmIQ4NL8x8Kernel("GemmKernel", pool, true)) + pool.Emit()
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "arm64", asm, quantRunCommon+q5x8RunSrc+q4x8RunSrc+iq4x8RunSrc+q5x8Decls, iq4x8RunTest)
	runArm64Gate(t, dir, ".", "TestGem[vm]IQ4|TestExactIQ4", asm)
}

func TestX64IQ4NL8x8KernelGate(t *testing.T) {
	_, argBytes := repackGemmArgs(true)
	pool := NewConstPool("iq4x_")
	asm := wrap("amd64", "GemvKernel", 16, argBytes, "avx2", x64GemvIQ4NL8x8Kernel("GemvKernel", pool, true)) +
		wrap("amd64", "GemmKernel", x64GemmQ5Frame, argBytes, "avx2", x64GemmIQ4NL8x8Kernel("GemmKernel", pool, true)) + pool.Emit()
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "amd64", asm, quantRunCommon+q5x8RunSrc+q4x8RunSrc+iq4x8RunSrc+q5x8Decls, iq4x8RunTest)
	runAmd64Gate(t, dir, ".", "TestGem[vm]IQ4|TestExactIQ4", asm)
}
