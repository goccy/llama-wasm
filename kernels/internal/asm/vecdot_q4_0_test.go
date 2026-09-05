package asm

import (
	"strings"
	"testing"
)

func TestVecDotQ4_0Q8_0KernelShape(t *testing.T) {
	a := a64VecDotQ4_0Kernel("Fn4dotprod", NewConstPool("t_"), true)
	for _, want := range []string{"sdot v10.4s, v2.16b, v6.16b", "sub v2.16b, v2.16b, v17.16b", "q4dloop2:", "q4dtail:", "l5+48(FP)"} {
		if !strings.Contains(a, want) {
			t.Errorf("a64 q4_0 dot missing %q", want)
		}
	}
	a = a64VecDotQ8_0Kernel("Fn8dotprod", NewConstPool("t_"), true)
	for _, want := range []string{"sdot v10.4s, v2.16b, v6.16b", "ldur q4, [x3, #18]", "q8dloop2:"} {
		if !strings.Contains(a, want) {
			t.Errorf("a64 q8_0 dot missing %q", want)
		}
	}
	if strings.Contains(a, "sub v") {
		t.Errorf("a64 q8_0 dot unpacks nibbles")
	}
	x := x64VecDotQ4_0Kernel("Fn4avx2", NewConstPool("t_"), true)
	for _, want := range []string{"VPSRLW\t$1, Y9, Y9", "VPSUBB\tY9, Y2, Y2", "VPMADDUBSW\tY4, Y5, Y5", "q4dblk:"} {
		if !strings.Contains(x, want) {
			t.Errorf("x64 q4_0 dot missing %q", want)
		}
	}
	x = x64VecDotQ8_0Kernel("Fn8avx2", NewConstPool("t_"), true)
	for _, want := range []string{"VMOVDQU\t2(SI), Y2", "VPSIGNB\tY2, Y4, Y4", "q8dblk:"} {
		if !strings.Contains(x, want) {
			t.Errorf("x64 q8_0 dot missing %q", want)
		}
	}
}

// legacyDotRunSrc: random q4_0 / q8_0 x q8_0 blocks against a float64
// reference.
const legacyDotRunSrc = `
func genQ4_0(n int, seed uint32) ([]byte, []byte, float64) {
	nb := n / 32
	s := lcg(seed)
	x := make([]byte, nb*18)
	y := make([]byte, nb*34)
	var want float64
	for b := 0; b < nb; b++ {
		xb, yb := x[b*18:], y[b*34:]
		dx, dy := f16bits(s.scale()), f16bits(s.scale())
		put16(xb, 0, dx)
		put16(yb, 0, dy)
		for i := 0; i < 16; i++ {
			xb[2+i] = s.byte_()
		}
		for i := 0; i < 32; i++ {
			yb[2+i] = byte(s.i8())
		}
		sum := 0
		for j := 0; j < 16; j++ {
			x0 := int(xb[2+j]&0x0f) - 8
			x1 := int(xb[2+j]>>4) - 8
			sum += x0*int(int8(yb[2+j])) + x1*int(int8(yb[2+j+16]))
		}
		want += f16val(dx) * f16val(dy) * float64(sum)
	}
	return x, y, want
}

func genQ8_0(n int, seed uint32) ([]byte, []byte, float64) {
	nb := n / 32
	s := lcg(seed)
	x := make([]byte, nb*34)
	y := make([]byte, nb*34)
	var want float64
	for b := 0; b < nb; b++ {
		xb, yb := x[b*34:], y[b*34:]
		dx, dy := f16bits(s.scale()), f16bits(s.scale())
		put16(xb, 0, dx)
		put16(yb, 0, dy)
		sum := 0
		for i := 0; i < 32; i++ {
			xb[2+i] = byte(s.i8())
			yb[2+i] = byte(s.i8())
			sum += int(int8(xb[2+i])) * int(int8(yb[2+i]))
		}
		want += f16val(dx) * f16val(dy) * float64(sum)
	}
	return x, y, want
}

func runQ4_0(t *testing.T, kernel dotKernel, n int) {
	t.Helper()
	x, y, want := genQ4_0(n, uint32(n)*2654435761+13)
	if got := callDot(t, kernel, n, x, y); !close32(got, want, 1e-5) {
		t.Fatalf("q4_0 n=%d dot = %v, want %v", n, got, want)
	}
}

func runQ8_0(t *testing.T, kernel dotKernel, n int) {
	t.Helper()
	x, y, want := genQ8_0(n, uint32(n)*2654435761+17)
	if got := callDot(t, kernel, n, x, y); !close32(got, want, 1e-5) {
		t.Fatalf("q8_0 n=%d dot = %v, want %v", n, got, want)
	}
}
`

const legacyDotDecls = "\nfunc Q4Kernel(m *mockModule, l0 int32, l1, l2, l3, l4, l5, l6 int64, l7 int32)\nfunc Q8Kernel(m *mockModule, l0 int32, l1, l2, l3, l4, l5, l6 int64, l7 int32)\nfunc trapstub()\n\nvar _ = trapstub\n"

const legacyDotRunTest = `package quantrun

import "testing"

func TestLegacyDot(t *testing.T) {
	for _, n := range []int{32, 64, 96, 0, 128, 896, 4864, 4864 + 32} {
		runQ4_0(t, Q4Kernel, n)
		runQ8_0(t, Q8Kernel, n)
	}
}
`

func TestA64VecDotQ4_0Q8_0KernelGate(t *testing.T) {
	_, argBytes := vecDotArgs(true)
	asm := wrap("arm64", "Q4Kernel", 16, argBytes, "dotprod", a64VecDotQ4_0Kernel("Q4Kernel", nil, true)) +
		wrap("arm64", "Q8Kernel", 16, argBytes, "dotprod", a64VecDotQ8_0Kernel("Q8Kernel", nil, true))
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "arm64", asm, quantRunCommon+legacyDotRunSrc+legacyDotDecls, legacyDotRunTest)
	runArm64Gate(t, dir, ".", "TestLegacyDot", asm)
}

func TestX64VecDotQ4_0Q8_0KernelGate(t *testing.T) {
	_, argBytes := vecDotArgs(true)
	pool := NewConstPool("lgx_")
	asm := wrap("amd64", "Q4Kernel", 16, argBytes, "avx2", x64VecDotQ4_0Kernel("Q4Kernel", pool, true)) +
		wrap("amd64", "Q8Kernel", 16, argBytes, "avx2", x64VecDotQ8_0Kernel("Q8Kernel", pool, true)) + pool.Emit()
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "amd64", asm, quantRunCommon+legacyDotRunSrc+legacyDotDecls, legacyDotRunTest)
	runAmd64Gate(t, dir, ".", "TestLegacyDot", asm)
}
