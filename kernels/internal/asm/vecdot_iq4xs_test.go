package asm

import (
	"strings"
	"testing"
)

func TestVecDotIQ4XSKernelShape(t *testing.T) {
	a := a64VecDotIQ4XSKernel("Fnixdotprod", NewConstPool("t_"), true)
	for _, want := range []string{"tbl v4.16b, {v18.16b}, v4.16b", "sdot v12.4s, v4.16b, v8.16b", "dup v21.4s, w7", "mla v20.4s, v12.4s, v21.4s", "MOVHU\t2(R3), R5", "ANDW\t$0x30, R8, R8", "SUBW\t$32, R7, R7", "addv s20, v20.4s", "ixblk:"} {
		if !strings.Contains(a, want) {
			t.Errorf("a64 iq4_xs dot missing %q", want)
		}
	}
	x := x64VecDotIQ4XSKernel("Fnixavx2", NewConstPool("t_"), true)
	for _, want := range []string{"VPSHUFB\tY2, Y11, Y2", "VPMULLD\tY6, Y5, Y5", "VPADDD\tY5, Y1, Y1", "MOVWLZX\t2(SI), R12", "SUBL\t$32, R10", "VMOVSS\t0(DX), X7", "ixblk:"} {
		if !strings.Contains(x, want) {
			t.Errorf("x64 iq4_xs dot missing %q", want)
		}
	}
}

// iq4xsRunSrc: random iq4_xs / q8_K blocks against a float64 reference
// (the generic body's arithmetic: per sub-block d * y.d * (ls - 32) * sumi).
const iq4xsRunSrc = `
func genIQ4XS(n int, seed uint32) ([]byte, []byte, float64) {
	nb := n / 256
	s := lcg(seed)
	x := make([]byte, nb*136)
	y := make([]byte, nb*292)
	var want float64
	for b := 0; b < nb; b++ {
		xb, yb := x[b*136:], y[b*292:]
		d := f16bits(s.scale())
		put16(xb, 0, d)
		for i := 2; i < 136; i++ {
			xb[i] = s.byte_()
		}
		yd := float32(int32(s.next()>>8)%200+1) / 64
		put32(yb, 0, yd)
		var sums [16]int
		for i := 0; i < 256; i++ {
			q := s.i8()
			yb[4+i] = byte(q)
			sums[i/16] += int(q)
		}
		for j := 0; j < 16; j++ {
			put16(yb, 260+2*j, uint16(int16(sums[j])))
		}
		h := uint32(xb[2]) | uint32(xb[3])<<8
		for ib := 0; ib < 8; ib += 2 {
			sl := xb[4+ib/2]
			ls1 := int((uint32(sl)&0xf)|((h<<4)&0x30)) - 32
			ls2 := int((uint32(sl)>>4)|((h<<2)&0x30)) - 32
			h >>= 4
			for k, ls := range []int{ls1, ls2} {
				sub := ib + k
				sumi := 0
				for j := 0; j < 16; j++ {
					q := xb[8+16*sub+j]
					sumi += int(kvaluesIQ4NL[q&0xf])*int(int8(yb[4+32*sub+j])) + int(kvaluesIQ4NL[q>>4])*int(int8(yb[4+32*sub+16+j]))
				}
				want += f16val(d) * float64(yd) * float64(ls) * float64(sumi)
			}
		}
	}
	return x, y, want
}

func runIQ4XS(t *testing.T, kernel dotKernel, n int) {
	t.Helper()
	x, y, want := genIQ4XS(n, uint32(n)*2654435761+23)
	if got := callDot(t, kernel, n, x, y); !close32(got, want, 1e-5) {
		t.Fatalf("iq4_xs n=%d dot = %v, want %v", n, got, want)
	}
}
`

const iq4xsDecls = "\nfunc IXKernel(m *mockModule, l0 int32, l1, l2, l3, l4, l5, l6 int64, l7 int32)\nfunc trapstub()\n\nvar _ = trapstub\n"

const iq4xsRunTest = `package quantrun

import "testing"

func TestIQ4XS(t *testing.T) {
	for _, n := range []int{256, 512, 0, 768, 1536, 4864} {
		runIQ4XS(t, IXKernel, n)
	}
}
`

func TestA64VecDotIQ4XSKernelGate(t *testing.T) {
	_, argBytes := vecDotArgs(true)
	pool := NewConstPool("ix_")
	asm := wrap("arm64", "IXKernel", 16, argBytes, "dotprod", a64VecDotIQ4XSKernel("IXKernel", pool, true)) + pool.Emit()
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "arm64", asm, quantRunCommon+q5x8RunSrc+iq4RunSrc+iq4xsRunSrc+iq4xsDecls, iq4xsRunTest)
	runArm64Gate(t, dir, ".", "TestIQ4XS", asm)
}

func TestX64VecDotIQ4XSKernelGate(t *testing.T) {
	_, argBytes := vecDotArgs(true)
	pool := NewConstPool("ixx_")
	asm := wrap("amd64", "IXKernel", 16, argBytes, "avx2", x64VecDotIQ4XSKernel("IXKernel", pool, true)) + pool.Emit()
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "amd64", asm, quantRunCommon+q5x8RunSrc+iq4RunSrc+iq4xsRunSrc+iq4xsDecls, iq4xsRunTest)
	runAmd64Gate(t, dir, ".", "TestIQ4XS", asm)
}
