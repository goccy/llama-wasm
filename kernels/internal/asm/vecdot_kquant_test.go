package asm

import (
	"strings"
	"testing"
)

func TestVecDotKQuantKernelShape(t *testing.T) {
	a := a64VecDotQ4_KKernel("Fn4dotprod", nil, true)
	for _, want := range []string{"ANDW\t$0x3f3f3f3f, R10, R12", "fmov d6, x12", "q4ktileblk:", "stur d0, [x8, #0]", "addp v9.8h, v7.8h, v8.8h", "smlal2 v10.4s, v9.8h, v6.8h", "fmls v0.4s, v10.4s, v12.s[0]", "mla v1.4s, v31.4s, v5.s[3]", "ldur q25, [x4, #244]", "q4kblk:"} {
		if !strings.Contains(a, want) {
			t.Errorf("a64 q4_K dot missing %q", want)
		}
	}
	b := a64VecDotQ6_KKernel("Fn6dotprod", nil, true)
	for _, want := range []string{"ldur q2, [x3, #192]", "sshll2 v7.4s, v3.8h, #0", "smlal2 v10.4s, v9.8h, v3.8h", "shl v10.4s, v10.4s, #5", "mla v1.4s, v11.4s, v7.s[3]", "ldur q27, [x4, #244]", "ldur h13, [x3, #208]", "q6kblk:", "q6ktileblk:", "fmla v0.4s, v1.4s, v30.4s"} {
		if !strings.Contains(b, want) {
			t.Errorf("a64 q6_K dot missing %q", want)
		}
	}
}

// kQuantRunSrc: q8_K activations with consistent block sums, q4_K and
// q6_K weights dequantized by the reference formulas of ggml-common.h
// (get_scale_min_k4, dequantize_row_q6_K), dotted in float64.
const kQuantRunSrc = `
// genQ8_K fills nb q8_K blocks and returns the dequantized activations.
func genQ8_K(s *lcg, nb int) ([]byte, []float64) {
	y := make([]byte, nb*292)
	vals := make([]float64, nb*256)
	for b := 0; b < nb; b++ {
		yb := y[b*292:]
		d := s.scale() / 16
		put32(yb, 0, d)
		var sums [16]int
		for i := 0; i < 256; i++ {
			q := s.i8()
			yb[4+i] = byte(q)
			sums[i/16] += int(q)
			vals[b*256+i] = float64(d) * float64(q)
		}
		for i := 0; i < 16; i++ {
			put16(yb, 260+2*i, uint16(int16(sums[i])))
		}
	}
	return y, vals
}

func scaleMinK4(sc []byte, j int) (int, int) {
	if j < 4 {
		return int(sc[j] & 63), int(sc[j+4] & 63)
	}
	return int(sc[j+4]&0xf) | int(sc[j-4]>>6)<<4, int(sc[j+4]>>4) | int(sc[j]>>6)<<4
}

func genQ4_K(n int, seed uint32) ([]byte, []byte, float64) {
	nb := n / 256
	s := lcg(seed)
	x := make([]byte, nb*144)
	y, yv := genQ8_K(&s, nb)
	var want float64
	for b := 0; b < nb; b++ {
		xb := x[b*144:]
		d, dmin := f16bits(s.scale()/4), f16bits(s.scale()/64)
		put16(xb, 0, d)
		put16(xb, 2, dmin)
		for i := 0; i < 12; i++ {
			xb[4+i] = s.byte_()
		}
		for i := 0; i < 128; i++ {
			xb[16+i] = s.byte_()
		}
		for j := 0; j < 8; j++ {
			sc, m := scaleMinK4(xb[4:16], j)
			for i := 0; i < 32; i++ {
				q := int(xb[16+32*(j/2)+i])
				if j%2 == 0 {
					q &= 0xf
				} else {
					q >>= 4
				}
				wv := f16val(d)*float64(sc)*float64(q) - f16val(dmin)*float64(m)
				want += wv * yv[b*256+32*j+i]
			}
		}
	}
	return x, y, want
}

func genQ6_K(n int, seed uint32) ([]byte, []byte, float64) {
	nb := n / 256
	s := lcg(seed)
	x := make([]byte, nb*210)
	y, yv := genQ8_K(&s, nb)
	var want float64
	for b := 0; b < nb; b++ {
		xb := x[b*210:]
		for i := 0; i < 192; i++ {
			xb[i] = s.byte_()
		}
		for i := 0; i < 16; i++ {
			xb[192+i] = byte(s.i8() / 2)
		}
		d := f16bits(s.scale() / 8)
		put16(xb, 208, d)
		for h := 0; h < 2; h++ {
			ql, qh, sc := xb[64*h:], xb[128+32*h:], xb[192+8*h:]
			for l := 0; l < 32; l++ {
				is := l / 16
				q1 := int(ql[l]&0xf|(qh[l]>>0&3)<<4) - 32
				q2 := int(ql[l+32]&0xf|(qh[l]>>2&3)<<4) - 32
				q3 := int(ql[l]>>4|(qh[l]>>4&3)<<4) - 32
				q4 := int(ql[l+32]>>4|(qh[l]>>6&3)<<4) - 32
				base := b*256 + 128*h + l
				want += f16val(d) * float64(int8(sc[is+0])) * float64(q1) * yv[base]
				want += f16val(d) * float64(int8(sc[is+2])) * float64(q2) * yv[base+32]
				want += f16val(d) * float64(int8(sc[is+4])) * float64(q3) * yv[base+64]
				want += f16val(d) * float64(int8(sc[is+6])) * float64(q4) * yv[base+96]
			}
		}
	}
	return x, y, want
}


// dotRef recomputes the reference dot of one q4_K/q6_K row against one
// q8_K column from already generated blocks by regenerating with the
// same seeds is not possible; instead the tile test builds each of the
// four combinations from generators seeded per (row, col) and checks
// the tile against four single dots of the same kernel (nrc == 1),
// which the numeric tests above pin to the float64 reference.
func runTile(t *testing.T, name string, kernel dotKernel, n int, gen func(int, uint32) ([]byte, []byte, float64)) {
	t.Helper()
	x0, y0, _ := gen(n, uint32(n)*97+1)
	x1, y1, _ := gen(n, uint32(n)*89+2)
	got := callDot2(t, kernel, n, x0, x1, y0, y1)
	want := [4]float32{
		callDot(t, kernel, n, x0, y0), callDot(t, kernel, n, x1, y0),
		callDot(t, kernel, n, x0, y1), callDot(t, kernel, n, x1, y1),
	}
	for i := range got {
		if !close32(got[i], float64(want[i]), 1e-5) {
			t.Fatalf("%s tile n=%d lane %d = %v, want %v (tile %v)", name, n, i, got[i], want[i], got)
		}
	}
}

func runQ4_K(t *testing.T, kernel dotKernel, n int) {
	t.Helper()
	x, y, want := genQ4_K(n, uint32(n)*2246822519+3)
	if got := callDot(t, kernel, n, x, y); !close32(got, want, 2e-5) {
		t.Fatalf("q4_K n=%d dot = %v, want %v", n, got, want)
	}
}

func runQ6_K(t *testing.T, kernel dotKernel, n int) {
	t.Helper()
	x, y, want := genQ6_K(n, uint32(n)*3266489917+5)
	if got := callDot(t, kernel, n, x, y); !close32(got, want, 2e-5) {
		t.Fatalf("q6_K n=%d dot = %v, want %v", n, got, want)
	}
}

func runQ4_KTile(t *testing.T, kernel dotKernel, n int) { runTile(t, "q4_K", kernel, n, genQ4_K) }
func runQ6_KTile(t *testing.T, kernel dotKernel, n int) { runTile(t, "q6_K", kernel, n, genQ6_K) }
`

const kQuantDecls = "\nfunc Q4KKernel(m *mockModule, l0 int32, l1, l2, l3, l4, l5, l6 int64, l7 int32)\nfunc Q6KKernel(m *mockModule, l0 int32, l1, l2, l3, l4, l5, l6 int64, l7 int32)\nfunc trapstub()\n\nvar _ = trapstub\n"

const kQuantRunTest = `package quantrun

import "testing"

func TestKQuant(t *testing.T) {
	for _, n := range []int{256, 512, 0, 768, 1536, 8960} {
		runQ4_K(t, Q4KKernel, n)
		runQ6_K(t, Q6KKernel, n)
		runQ4_KTile(t, Q4KKernel, n)
		runQ6_KTile(t, Q6KKernel, n)
	}
}
`

func TestA64VecDotKQuantKernelGate(t *testing.T) {
	_, argBytes := vecDotArgs(true)
	asm := wrap("arm64", "Q4KKernel", 16, argBytes, "dotprod", a64VecDotQ4_KKernel("Q4KKernel", nil, true)) +
		wrap("arm64", "Q6KKernel", 16, argBytes, "dotprod", a64VecDotQ6_KKernel("Q6KKernel", nil, true))
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "arm64", asm, quantRunCommon+kQuantRunSrc+kQuantDecls, kQuantRunTest)
	runArm64Gate(t, dir, ".", "TestKQuant", asm)
}

func TestX64VecDotQuantKernelShape(t *testing.T) {
	pool := NewConstPool("t_")
	a := x64VecDotQ5_0Kernel("Fn5avx2", pool, true)
	for _, want := range []string{"VPSHUFB\tY11, Y3, Y3", "VPSIGNB\tY2, Y4, Y4", "VPMADDUBSW\tY4, Y5, Y5", "VPMADDWD\tY10, Y5, Y5", "q5blk:", "l5+48(FP)"} {
		if !strings.Contains(a, want) {
			t.Errorf("x64 q5_0 dot missing %q", want)
		}
	}
	b := x64VecDotQ4_KKernel("Fn4avx2", pool, true)
	for _, want := range []string{"VPINSRD\t$3, R13, X2, X2", "VPHADDW\tX5, X4, X4", "VFNMADD231PS\tX3, X6, X1", "VPMADDUBSW\t196(DX), Y3, Y3", "VPSHUFB\t224(R11), Y2, Y5", "q4kblk:", "q4kblkd:", "q4ktile:"} {
		if !strings.Contains(b, want) {
			t.Errorf("x64 q4_K dot missing %q", want)
		}
	}
	c := x64VecDotQ6_KKernel("Fn6avx2", pool, true)
	for _, want := range []string{"VPMADDWD\t260(DX), Y13, Y13", "VPSLLD\t$5, Y13, Y13", "VPMOVSXBW\t112(R11), Y14", "VPMADDUBSW\t228(DX), Y6, Y6", "VPSUBD\tY13, Y7, Y7", "MOVWLZX\t208(SI), R8", "q6kblkc:"} {
		if !strings.Contains(c, want) {
			t.Errorf("x64 q6_K dot missing %q", want)
		}
	}
	k := x64QuantConsts()
	if len(k) != 672 || k[96+8] != 1 || k[128] != 0xfe || k[288+32*3] != 6 || k[288+32*3+1] != 7 || k[544+16*7+8] != 15 {
		t.Errorf("x64 quant const blob layout")
	}
}

const x64QuantDecls = "\nfunc Q5Kernel(m *mockModule, l0 int32, l1, l2, l3, l4, l5, l6 int64, l7 int32)\nfunc Q4KKernel(m *mockModule, l0 int32, l1, l2, l3, l4, l5, l6 int64, l7 int32)\nfunc Q6KKernel(m *mockModule, l0 int32, l1, l2, l3, l4, l5, l6 int64, l7 int32)\nfunc trapstub()\n\nvar _ = trapstub\n"

const x64QuantRunTest = `package quantrun

import "testing"

func TestQuant(t *testing.T) {
	for _, n := range []int{32, 64, 96, 0, 128, 896, 4864} {
		runQ5_0(t, Q5Kernel, n)
	}
	for _, n := range []int{256, 512, 0, 768, 1536, 8960} {
		runQ4_K(t, Q4KKernel, n)
		runQ6_K(t, Q6KKernel, n)
		runQ4_KTile(t, Q4KKernel, n)
		runQ6_KTile(t, Q6KKernel, n)
	}
}
`

func TestX64VecDotQuantKernelGate(t *testing.T) {
	_, argBytes := vecDotArgs(true)
	var asm string
	for _, k := range []struct {
		sym string
		gen func(string, *ConstPool, bool) string
	}{{"Q5Kernel", x64VecDotQ5_0Kernel}, {"Q4KKernel", x64VecDotQ4_KKernel}, {"Q6KKernel", x64VecDotQ6_KKernel}} {
		pool := NewConstPool(k.sym + "_")
		asm += wrap("amd64", k.sym, 16, argBytes, "avx2", k.gen(k.sym, pool, true)+"\n"+pool.Emit())
	}
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "amd64", asm, quantRunCommon+q5_0RunSrc+kQuantRunSrc+x64QuantDecls, x64QuantRunTest)
	runAmd64Gate(t, dir, ".", "TestQuant", asm)
}
