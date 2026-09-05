package asm

import (
	"fmt"
	"strings"
	"testing"
)

func TestVecDotIQ1KernelShape(t *testing.T) {
	a := a64VecDotIQ1SKernel("Fni1sdotprod", NewConstPool("t_"), true)
	for _, want := range []string{"UBFX\t$9, R6, $3, R8", "ORR\tR8<<8, R7, R7", "MOVD\t(R12)(R7<<3), R8", "UBFX\t$12, R6, $3, R7", "MOVH\t262(R4), R9", "TBZ\t$15, R6, i1spos7", "NEGW\tR8, R8", "mov v25.s[3], w8", "fmla v20.4s, v24.4s, v17.s[0]"} {
		if !strings.Contains(a, want) {
			t.Errorf("a64 iq1_s dot missing %q", want)
		}
	}
	b := a64VecDotIQ1MKernel("Fni1mdotprod", NewConstPool("t_"), true)
	for _, want := range []string{"UBFX\t$12, R6, $3, R8", "dup v4.16b, w6", "cmtst v4.16b, v4.16b, v18.16b", "sdot v14.4s, v4.16b, v6.16b", "UBFX\t$9, R10, $3, R7", "LSRW\t$12, R7, R7", "ANDW\t$0xf000, R8, R8", "fmov s22, w7", "fcvt s22, h22"} {
		if !strings.Contains(b, want) {
			t.Errorf("a64 iq1_m dot missing %q", want)
		}
	}
	if c := iq1Consts(); len(c) != 16400 || c[16384] != 0x08 || c[16384+8] != 0x80 {
		t.Errorf("iq1 const blob")
	}
}

// iq1RunSrc: random iq1_s / iq1_m blocks against float64 references
// following the generic bodies.
var iq1RunSrc = fmt.Sprintf(`
var iq1sGridT = %s

func gridDot(idx uint32, q8 []byte) (dot, ysum int) {
	g := iq1sGridT[idx]
	for j := 0; j < 8; j++ {
		dot += int(int8(g>>(8*uint(j)))) * int(int8(q8[j]))
		ysum += int(int8(q8[j]))
	}
	return
}

func genIQ1S(n int, seed uint32) ([]byte, []byte, float64) {
	nb := n / 256
	s := lcg(seed)
	x := make([]byte, nb*50)
	y := make([]byte, nb*292)
	var want float64
	for b := 0; b < nb; b++ {
		xb, yb := x[b*50:], y[b*292:]
		d := f16bits(s.scale())
		put16(xb, 0, d)
		for i := 2; i < 50; i++ {
			xb[i] = s.byte_()
		}
		yd := float32(int32(s.next()>>8)%%200+1) / 64
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
		sumi, sumi1 := 0, 0
		for ib := 0; ib < 8; ib++ {
			qh := uint32(xb[34+2*ib]) | uint32(xb[35+2*ib])<<8
			ls := int(2*((qh>>12)&7) + 1)
			delta := 1
			if qh&0x8000 != 0 {
				delta = -1
			}
			lsum := 0
			for l := 0; l < 4; l++ {
				dot, _ := gridDot(uint32(xb[2+4*ib+l])|(((qh>>(3*uint(l)))&7)<<8), yb[4+32*ib+8*l:])
				lsum += dot
			}
			sumi += ls * lsum
			sumi1 += ls * delta * (sums[2*ib] + sums[2*ib+1])
		}
		want += f16val(d) * float64(yd) * (float64(sumi) + 0.125*float64(sumi1))
	}
	return x, y, want
}

func genIQ1M(n int, seed uint32) ([]byte, []byte, float64) {
	nb := n / 256
	s := lcg(seed)
	x := make([]byte, nb*56)
	y := make([]byte, nb*292)
	var want float64
	for b := 0; b < nb; b++ {
		xb, yb := x[b*56:], y[b*292:]
		for i := 0; i < 56; i++ {
			xb[i] = s.byte_()
		}
		// keep the assembled f16 scale finite and sane: exponent nibbles in the low half
		sc := []uint16{0, 0, 0, 0}
		for i := 0; i < 4; i++ {
			sc[i] = uint16(xb[48+2*i]) | uint16(xb[49+2*i])<<8
		}
		scale := f16bits(s.scale())
		sc[0] = sc[0]&0x0fff | (scale&0x000f)<<12
		sc[1] = sc[1]&0x0fff | (scale&0x00f0)<<8
		sc[2] = sc[2]&0x0fff | (scale&0x0f00)<<4
		sc[3] = sc[3]&0x0fff | (scale & 0xf000)
		for i := 0; i < 4; i++ {
			put16(xb, 48+2*i, sc[i])
		}
		yd := float32(int32(s.next()>>8)%%200+1) / 64
		put32(yb, 0, yd)
		for i := 0; i < 256; i++ {
			yb[4+i] = byte(s.i8())
		}
		sumi1, sumi2 := 0, 0
		for ib := 0; ib < 8; ib++ {
			qh0, qh1 := xb[32+2*ib], xb[33+2*ib]
			delta := [4]int{1, 1, 1, 1}
			if qh0&0x08 != 0 {
				delta[0] = -1
			}
			if qh0&0x80 != 0 {
				delta[1] = -1
			}
			if qh1&0x08 != 0 {
				delta[2] = -1
			}
			if qh1&0x80 != 0 {
				delta[3] = -1
			}
			var sum1, sum2 [2]int
			for l := 0; l < 4; l++ {
				qh := uint32(xb[32+2*ib+l/2])
				idx := uint32(xb[4*ib+l]) | ((qh << (8 - 4*uint(l%%2))) & 0x700)
				dot, ysum := gridDot(idx, yb[4+32*ib+8*l:])
				sum1[l/2] += dot
				sum2[l/2] += ysum * delta[l]
			}
			ls1 := int(2*((sc[ib/2]>>(6*uint(ib%%2)))&7) + 1)
			ls2 := int(2*((sc[ib/2]>>(6*uint(ib%%2)+3))&7) + 1)
			sumi1 += sum1[0]*ls1 + sum1[1]*ls2
			sumi2 += sum2[0]*ls1 + sum2[1]*ls2
		}
		want += f16val(scale) * float64(yd) * (float64(sumi1) + 0.125*float64(sumi2))
	}
	return x, y, want
}

func runIQ1S(t *testing.T, kernel dotKernel, n int) {
	t.Helper()
	x, y, want := genIQ1S(n, uint32(n)*2654435761+41)
	if got := callDot(t, kernel, n, x, y); !close32(got, want, 1e-5) {
		t.Fatalf("iq1_s n=%%d dot = %%v, want %%v", n, got, want)
	}
}

func runIQ1M(t *testing.T, kernel dotKernel, n int) {
	t.Helper()
	x, y, want := genIQ1M(n, uint32(n)*2654435761+43)
	if got := callDot(t, kernel, n, x, y); !close32(got, want, 1e-5) {
		t.Fatalf("iq1_m n=%%d dot = %%v, want %%v", n, got, want)
	}
}
`, goTable64(iq1sGrid[:]))

const iq1Decls = "\nfunc I1SKernel(m *mockModule, l0 int32, l1, l2, l3, l4, l5, l6 int64, l7 int32)\nfunc I1MKernel(m *mockModule, l0 int32, l1, l2, l3, l4, l5, l6 int64, l7 int32)\nfunc trapstub()\n\nvar _ = trapstub\n"

const iq1RunTest = `package quantrun

import "testing"

func TestIQ1(t *testing.T) {
	for _, n := range []int{256, 512, 0, 768, 1536, 4864} {
		runIQ1S(t, I1SKernel, n)
		runIQ1M(t, I1MKernel, n)
	}
}
`

func TestA64VecDotIQ1KernelGate(t *testing.T) {
	_, argBytes := vecDotArgs(true)
	pool := NewConstPool("i1_")
	asm := wrap("arm64", "I1SKernel", 16, argBytes, "dotprod", a64VecDotIQ1SKernel("I1SKernel", pool, true)) +
		wrap("arm64", "I1MKernel", 16, argBytes, "dotprod", a64VecDotIQ1MKernel("I1MKernel", pool, true)) + pool.Emit()
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "arm64", asm, quantRunCommon+iq1RunSrc+iq1Decls, iq1RunTest)
	runArm64Gate(t, dir, ".", "TestIQ1", asm)
}

func TestX64VecDotIQ1KernelGate(t *testing.T) {
	_, argBytes := vecDotArgs(true)
	pool := NewConstPool("i1x_")
	asm := wrap("amd64", "I1SKernel", 16, argBytes, "avx2", x64VecDotIQ1SKernel("I1SKernel", pool, true)) +
		wrap("amd64", "I1MKernel", 16, argBytes, "avx2", x64VecDotIQ1MKernel("I1MKernel", pool, true)) + pool.Emit()
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "amd64", asm, quantRunCommon+iq1RunSrc+iq1Decls, iq1RunTest)
	runAmd64Gate(t, dir, ".", "TestIQ1", asm)
}
