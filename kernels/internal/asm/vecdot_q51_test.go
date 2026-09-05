package asm

import (
	"strings"
	"testing"
)

func TestVecDotQx1KernelShape(t *testing.T) {
	a := a64VecDotQ5_1Kernel("Fn4dotprod", NewConstPool("q51_"), true)
	for _, want := range []string{"q51loop2:", "q51reduce:", "cmtst v", "ldur h", "fadd s30, s30", "mov v31.s[0], v30.s[0]"} {
		if !strings.Contains(a, want) {
			t.Errorf("a64 q5_1 dot missing %q", want)
		}
	}
	b := a64VecDotQ4_1Kernel("Fn4dotprod", NewConstPool("q41_"), true)
	if strings.Contains(b, "cmtst") || !strings.Contains(b, "q41loop2:") {
		t.Errorf("a64 q4_1 dot shape")
	}
	x := x64VecDotQ5_1Kernel("Fn4avx2", NewConstPool("q51x_"), true)
	for _, want := range []string{"q51blk:", "VPMADDUBSW\tY4, Y2, Y5", "VPBROADCASTD\t4(SI), Y3", "VADDSS\tX6, X1, X1", "VADDPS\tX1, X0, X0"} {
		if !strings.Contains(x, want) {
			t.Errorf("x64 q5_1 dot missing %q", want)
		}
	}
	y := x64VecDotQ4_1Kernel("Fn4avx2", NewConstPool("q41x_"), true)
	if strings.Contains(y, "VPBROADCASTD") || !strings.Contains(y, "VMOVDQU\t4(SI), X2") {
		t.Errorf("x64 q4_1 dot shape")
	}
}

// qx1RunSrc: q5_1 / q4_1 rows against q8_1 columns (d, s = d * sum q, qs)
// with float64 references.
const qx1RunSrc = `
func genQ8_1(s *lcg, nb int) ([]byte, []float64) {
	y := make([]byte, 36*nb)
	v := make([]float64, 32*nb)
	for b := 0; b < nb; b++ {
		d := s.scale() / 16
		put16(y, 36*b, f16bits(d))
		dv := f16val(f16bits(d))
		sum := 0
		for e := 0; e < 32; e++ {
			q := s.i8()
			y[36*b+4+e] = byte(q)
			sum += int(q)
			v[32*b+e] = float64(q) * dv
		}
		put16(y, 36*b+2, f16bits(float32(dv*float64(sum))))
	}
	return y, v
}

// genQx1: q5_1 (fifth) or q4_1 rows; the reference uses the same f16 s
// the kernel reads for the min term.
func genQx1(n int, seed uint32, fifth bool) ([]byte, []byte, float64) {
	nb := n / 32
	s := lcg(seed)
	y, yv := genQ8_1(&s, nb)
	xb := 20
	if fifth {
		xb = 24
	}
	x := make([]byte, xb*nb)
	var want float64
	for b := 0; b < nb; b++ {
		d, m := s.scale(), s.scale()/8
		put16(x, xb*b, f16bits(d))
		put16(x, xb*b+2, f16bits(m))
		dv, mv := f16val(f16bits(d)), f16val(f16bits(m))
		qs := xb*b + 4
		var qh uint32
		if fifth {
			qs = xb*b + 8
		}
		for j := 0; j < 16; j++ {
			lim := uint32(16)
			if fifth {
				lim = 32
			}
			q0 := int(s.next() % lim)
			q1 := int(s.next() % lim)
			x[qs+j] = byte(q0&15) | byte(q1&15)<<4
			qh |= uint32(q0>>4) << j
			qh |= uint32(q1>>4) << (j + 16)
			want += float64(q0) * dv * yv[32*b+j]
			want += float64(q1) * dv * yv[32*b+j+16]
		}
		if fifth {
			x[xb*b+4], x[xb*b+5], x[xb*b+6], x[xb*b+7] = byte(qh), byte(qh>>8), byte(qh>>16), byte(qh>>24)
		}
		ys := f16val(uint16(y[36*b+2]) | uint16(y[36*b+3])<<8)
		want += mv * ys
	}
	return x, y, want
}

func runQx1(t *testing.T, name string, kernel dotKernel, n int, fifth bool) {
	t.Helper()
	x, y, want := genQx1(n, uint32(n)*2654435761+23, fifth)
	if got := callDot(t, kernel, n, x, y); !close32(got, want, 2e-5) {
		t.Fatalf("%s n=%d dot = %v, want %v", name, n, got, want)
	}
}
`

const qx1Decls = "\nfunc Q51Kernel(m *mockModule, l0 int32, l1, l2, l3, l4, l5, l6 int64, l7 int32)\nfunc Q41Kernel(m *mockModule, l0 int32, l1, l2, l3, l4, l5, l6 int64, l7 int32)\nfunc trapstub()\n\nvar _ = trapstub\n"

const qx1RunTest = `package quantrun

import "testing"

func TestQx1(t *testing.T) {
	for _, n := range []int{32, 64, 96, 256, 896, 2048} {
		runQx1(t, "q5_1", Q51Kernel, n, true)
		runQx1(t, "q4_1", Q41Kernel, n, false)
	}
}
`

func TestA64VecDotQx1KernelGate(t *testing.T) {
	_, argBytes := vecDotArgs(true)
	pool := NewConstPool("qx1_")
	asm := wrap("arm64", "Q51Kernel", 16, argBytes, "dotprod", a64VecDotQ5_1Kernel("Q51Kernel", pool, true)) +
		wrap("arm64", "Q41Kernel", 16, argBytes, "dotprod", a64VecDotQ4_1Kernel("Q41Kernel", pool, true)) + pool.Emit()
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "arm64", asm, quantRunCommon+qx1RunSrc+qx1Decls, qx1RunTest)
	runArm64Gate(t, dir, ".", "TestQx1", asm)
}

func TestX64VecDotQx1KernelGate(t *testing.T) {
	_, argBytes := vecDotArgs(true)
	pool := NewConstPool("qx1x_")
	asm := wrap("amd64", "Q51Kernel", 16, argBytes, "avx2", x64VecDotQ5_1Kernel("Q51Kernel", pool, true)) +
		wrap("amd64", "Q41Kernel", 16, argBytes, "avx2", x64VecDotQ4_1Kernel("Q41Kernel", pool, true)) + pool.Emit()
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "amd64", asm, quantRunCommon+qx1RunSrc+qx1Decls, qx1RunTest)
	runAmd64Gate(t, dir, ".", "TestQx1", asm)
}
