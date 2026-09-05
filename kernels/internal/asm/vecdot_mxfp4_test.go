package asm

import (
	"strings"
	"testing"
)

func TestVecDotMXFP4KernelShape(t *testing.T) {
	a := a64VecDotMXFP4Kernel("Fnmxdotprod", NewConstPool("t_"), true)
	for _, want := range []string{"MOVBU\t0(R3), R5", "MOVBU\t17(R3), R5", "LSLW\t$23, R6, R6", "CSELW\tLO, R7, R6, R6", "fmov s14, w6", "ldur q2, [x3, #1]", "mx4loop2:", "mx4tail:"} {
		if !strings.Contains(a, want) {
			t.Errorf("a64 mxfp4 dot missing %q", want)
		}
	}
	if strings.Contains(a, "fcvt s14, h14") {
		t.Errorf("a64 mxfp4 dot converts an f16 scale")
	}
	x := x64VecDotMXFP4Kernel("Fnmxavx2", NewConstPool("t_"), true)
	for _, want := range []string{"MOVBLZX\t0(SI), R9", "SHLL\t$23, R10", "CMOVLCS\tR11, R10", "VMOVDQU\t1(SI), X2", "mx4blk:"} {
		if !strings.Contains(x, want) {
			t.Errorf("x64 mxfp4 dot missing %q", want)
		}
	}
	c := lut32Consts(lut32MXFP4)
	if int8(c[7]) != 12 || int8(c[15]) != -12 || c[8] != 0 {
		t.Errorf("mxfp4 table %v", c)
	}
}

// mxfp4RunSrc: random mxfp4 / q8_0 blocks against a float64 reference.
// E8M0 exponents cover the normal range and the two denormal codes.
const mxfp4RunSrc = `
var kvaluesFP4 = [16]int8{0, 1, 2, 3, 4, 6, 8, 12, 0, -1, -2, -3, -4, -6, -8, -12}

func genMXFP4(n int, seed uint32) ([]byte, []byte, float64) {
	nb := n / 32
	s := lcg(seed)
	x := make([]byte, nb*17)
	y := make([]byte, nb*34)
	var want float64
	for b := 0; b < nb; b++ {
		xb, yb := x[b*17:], y[b*34:]
		e := byte(118 + s.next()%20)
		if b%7 == 3 {
			e = byte(s.next() % 3) // 0, 1 (denormal patterns) or 2
		}
		xb[0] = e
		for i := 0; i < 16; i++ {
			xb[1+i] = s.byte_()
		}
		dy := f16bits(s.scale())
		put16(yb, 0, dy)
		sum := 0
		for i := 0; i < 32; i++ {
			yb[2+i] = byte(s.i8())
		}
		for j := 0; j < 16; j++ {
			sum += int(kvaluesFP4[xb[1+j]&0xf])*int(int8(yb[2+j])) + int(kvaluesFP4[xb[1+j]>>4])*int(int8(yb[2+j+16]))
		}
		want += math.Ldexp(1, int(e)-128) * f16val(dy) * float64(sum)
	}
	return x, y, want
}

func runMXFP4(t *testing.T, kernel dotKernel, n int) {
	t.Helper()
	x, y, want := genMXFP4(n, uint32(n)*2654435761+29)
	if got := callDot(t, kernel, n, x, y); !close32(got, want, 1e-5) {
		t.Fatalf("mxfp4 n=%d dot = %v, want %v", n, got, want)
	}
}
`

const mxfp4Decls = "\nfunc MXKernel(m *mockModule, l0 int32, l1, l2, l3, l4, l5, l6 int64, l7 int32)\nfunc trapstub()\n\nvar _ = trapstub\n"

const mxfp4RunTest = `package quantrun

import "testing"

func TestMXFP4(t *testing.T) {
	for _, n := range []int{32, 64, 96, 0, 224, 896, 4864} {
		runMXFP4(t, MXKernel, n)
	}
}
`

func TestA64VecDotMXFP4KernelGate(t *testing.T) {
	_, argBytes := vecDotArgs(true)
	pool := NewConstPool("mx_")
	asm := wrap("arm64", "MXKernel", 16, argBytes, "dotprod", a64VecDotMXFP4Kernel("MXKernel", pool, true)) + pool.Emit()
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "arm64", asm, quantRunCommon+mxfp4RunSrc+mxfp4Decls, mxfp4RunTest)
	runArm64Gate(t, dir, ".", "TestMXFP4", asm)
}

func TestX64VecDotMXFP4KernelGate(t *testing.T) {
	_, argBytes := vecDotArgs(true)
	pool := NewConstPool("mxx_")
	asm := wrap("amd64", "MXKernel", 16, argBytes, "avx2", x64VecDotMXFP4Kernel("MXKernel", pool, true)) + pool.Emit()
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "amd64", asm, quantRunCommon+mxfp4RunSrc+mxfp4Decls, mxfp4RunTest)
	runAmd64Gate(t, dir, ".", "TestMXFP4", asm)
}
