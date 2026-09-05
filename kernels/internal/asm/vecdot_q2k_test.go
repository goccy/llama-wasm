package asm

import (
	"strings"
	"testing"
)

func TestVecDotQ2KKernelShape(t *testing.T) {
	a := a64VecDotQ2_KKernel("Fn4dotprod", nil, true)
	for _, want := range []string{"q2kblk:", "q2kzero:", "ovr_oob", "sdot v28.4s", "mla v1.4s", "ldur h18, [x3, #82]"} {
		if !strings.Contains(a, want) {
			t.Errorf("a64 q2_K dot missing %q", want)
		}
	}
	b := x64VecDotQ2_KKernel("Fn4avx2", NewConstPool("q2kt_"), true)
	for _, want := range []string{"q2kblk", "VPMADDUBSW", "VPMOVZXBW\tX14, Y14", "VFNMADD231PS\tY13, Y6, Y0"} {
		if !strings.Contains(b, want) {
			t.Errorf("x64 q2_K dot missing %q", want)
		}
	}
}

// q2KRunSrc: plain q2_K rows and their float64 reference dot.
const q2KRunSrc = `
func genQ2_K(n int, seed uint32) ([]byte, []byte, float64) {
	nb := n / 256
	s := lcg(seed)
	x := make([]byte, nb*84)
	y, yv := genQ8_K(&s, nb)
	var want float64
	for b := 0; b < nb; b++ {
		xb := x[b*84:]
		for i := 0; i < 80; i++ {
			xb[i] = s.byte_()
		}
		d, dmin := f16bits(s.scale()/2), f16bits(s.scale()/16)
		put16(xb, 80, d)
		put16(xb, 82, dmin)
		for j := 0; j < 2; j++ {
			for sh := 0; sh < 4; sh++ {
				for l := 0; l < 32; l++ {
					is := 8*j + 2*sh + l/16
					sc := float64(xb[is] & 0xf)
					m := float64(xb[is] >> 4)
					q := float64((xb[16+32*j+l] >> (2 * sh)) & 3)
					wv := f16val(d)*sc*q - f16val(dmin)*m
					want += wv * yv[b*256+128*j+32*sh+l]
				}
			}
		}
	}
	return x, y, want
}

func runQ2_K(t *testing.T, kernel dotKernel, n int) {
	t.Helper()
	x, y, want := genQ2_K(n, uint32(n)*2246822519+11)
	if got := callDot(t, kernel, n, x, y); !close32(got, want, 2e-5) {
		t.Fatalf("q2_K n=%d dot = %v, want %v", n, got, want)
	}
}
`

const q2KDecls = "\nfunc Q2KKernel(m *mockModule, l0 int32, l1, l2, l3, l4, l5, l6 int64, l7 int32)\nfunc trapstub()\n\nvar _ = trapstub\n"

const q2KRunTest = `package quantrun

import "testing"

func TestQ2K(t *testing.T) {
	for _, n := range []int{256, 512, 1024, 2048} {
		runQ2_K(t, Q2KKernel, n)
	}
}
`

func TestA64VecDotQ2KKernelGate(t *testing.T) {
	_, argBytes := vecDotArgs(true)
	asm := wrap("arm64", "Q2KKernel", 16, argBytes, "dotprod", a64VecDotQ2_KKernel("Q2KKernel", nil, true))
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "arm64", asm, quantRunCommon+kQuantRunSrc+q2KRunSrc+q2KDecls, q2KRunTest)
	runArm64Gate(t, dir, ".", "TestQ2K", asm)
}

func TestX64VecDotQ2KKernelGate(t *testing.T) {
	_, argBytes := vecDotArgs(true)
	pool := NewConstPool("q2kx_")
	asm := wrap("amd64", "Q2KKernel", 16, argBytes, "avx2", x64VecDotQ2_KKernel("Q2KKernel", pool, true)+"\n"+pool.Emit())
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "amd64", asm, quantRunCommon+kQuantRunSrc+q2KRunSrc+q2KDecls, q2KRunTest)
	runAmd64Gate(t, dir, ".", "TestQ2K", asm)
}
