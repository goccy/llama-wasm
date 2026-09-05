package asm

import (
	"strings"
	"testing"
)

func TestVecDotIQ4NLKernelShape(t *testing.T) {
	a := a64VecDotIQ4NLKernel("Fn4dotprod", NewConstPool("i4_"), true)
	for _, want := range []string{"iq4loop2:", "iq4tail:", "iq4reduce:", "tbl v4.16b, {v18.16b}, v4.16b", "sdot v12.4s"} {
		if !strings.Contains(a, want) {
			t.Errorf("a64 iq4_nl dot missing %q", want)
		}
	}
	b := x64VecDotIQ4NLKernel("Fn4avx2", NewConstPool("i4x_"), true)
	for _, want := range []string{"iq4blk:", "VPSHUFB\tY2, Y11, Y2", "VPSIGNB\tY2, Y4, Y4", "VPMADDUBSW\tY4, Y5, Y5"} {
		if !strings.Contains(b, want) {
			t.Errorf("x64 iq4_nl dot missing %q", want)
		}
	}
}

// iq4RunSrc: iq4_nl rows against q8_0 columns with a float64 reference;
// genQ8Row comes from q5x8RunSrc, callDot/dotKernel from quantRunCommon.
const iq4RunSrc = `
var kvaluesIQ4NL = [16]int8{-127, -104, -83, -65, -49, -35, -22, -10, 1, 13, 25, 38, 53, 69, 89, 113}

func genIQ4(n int, seed uint32) ([]byte, []byte, float64) {
	nb := n / 32
	s := lcg(seed)
	x := make([]byte, 18*nb)
	y, yv := genQ8Row(&s, nb)
	var want float64
	for b := 0; b < nb; b++ {
		d := s.scale()
		put16(x, 18*b, f16bits(d))
		dv := f16val(f16bits(d))
		for j := 0; j < 16; j++ {
			q0 := int(s.next() % 16)
			q1 := int(s.next() % 16)
			x[18*b+2+j] = byte(q0) | byte(q1)<<4
			want += float64(kvaluesIQ4NL[q0]) * dv * yv[32*b+j]
			want += float64(kvaluesIQ4NL[q1]) * dv * yv[32*b+j+16]
		}
	}
	return x, y, want
}

func runIQ4(t *testing.T, kernel dotKernel, n int) {
	t.Helper()
	x, y, want := genIQ4(n, uint32(n)*2654435761+19)
	if got := callDot(t, kernel, n, x, y); !close32(got, want, 2e-5) {
		t.Fatalf("iq4_nl n=%d dot = %v, want %v", n, got, want)
	}
}
`

const iq4Decls = "\nfunc IQ4Kernel(m *mockModule, l0 int32, l1, l2, l3, l4, l5, l6 int64, l7 int32)\nfunc trapstub()\n\nvar _ = trapstub\n"

const iq4RunTest = `package quantrun

import "testing"

func TestIQ4(t *testing.T) {
	for _, n := range []int{32, 64, 96, 256, 896, 2048} {
		runIQ4(t, IQ4Kernel, n)
	}
}
`

func TestA64VecDotIQ4NLKernelGate(t *testing.T) {
	_, argBytes := vecDotArgs(true)
	pool := NewConstPool("i4_")
	asm := wrap("arm64", "IQ4Kernel", 16, argBytes, "dotprod", a64VecDotIQ4NLKernel("IQ4Kernel", pool, true)+"\n"+pool.Emit())
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "arm64", asm, quantRunCommon+q5x8RunSrc+iq4RunSrc+iq4Decls, iq4RunTest)
	runArm64Gate(t, dir, ".", "TestIQ4", asm)
}

func TestX64VecDotIQ4NLKernelGate(t *testing.T) {
	_, argBytes := vecDotArgs(true)
	pool := NewConstPool("i4x_")
	asm := wrap("amd64", "IQ4Kernel", 16, argBytes, "avx2", x64VecDotIQ4NLKernel("IQ4Kernel", pool, true)+"\n"+pool.Emit())
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "amd64", asm, quantRunCommon+q5x8RunSrc+iq4RunSrc+iq4Decls, iq4RunTest)
	runAmd64Gate(t, dir, ".", "TestIQ4", asm)
}
