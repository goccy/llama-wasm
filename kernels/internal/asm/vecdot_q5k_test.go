package asm

import (
	"strings"
	"testing"
)

func TestVecDotQ5KKernelShape(t *testing.T) {
	a := a64VecDotQ5_KKernel("Fn4dotprod", nil, true)
	for _, want := range []string{"q5kblk:", "q5ktile:", "q5ktileblk:", "ovr_oob", "shl v17.16b, v17.16b, #4", "shl v17.16b, v17.16b, #3", "ldur q18, [x3, #16]"} {
		if !strings.Contains(a, want) {
			t.Errorf("a64 q5_K dot missing %q", want)
		}
	}
	pool := NewConstPool("q5kt_")
	b := x64VecDotQ5_KKernel("Fn4avx2", pool, true)
	for _, want := range []string{"q5kblk", "VMOVDQU\t16(SI), Y9", "VPSLLW\t$4, Y13, Y13", "VPSLLW\t$3, Y13, Y13", "VPMADDUBSW"} {
		if !strings.Contains(b, want) {
			t.Errorf("x64 q5_K dot missing %q", want)
		}
	}
}

// q5KRunSrc: plain q5_K rows (d, dmin, scales[12], qh[32], qs[128]) and
// their float64 reference dot against a q8_K column.
const q5KRunSrc = `
func genQ5_K(n int, seed uint32) ([]byte, []byte, float64) {
	nb := n / 256
	s := lcg(seed)
	x := make([]byte, nb*176)
	y, yv := genQ8_K(&s, nb)
	var want float64
	for b := 0; b < nb; b++ {
		xb := x[b*176:]
		d, dmin := f16bits(s.scale()/8), f16bits(s.scale()/64)
		put16(xb, 0, d)
		put16(xb, 2, dmin)
		for i := 4; i < 176; i++ {
			xb[i] = s.byte_()
		}
		for j := 0; j < 8; j++ {
			sc, m := scaleMinK4(xb[4:16], j)
			for i := 0; i < 32; i++ {
				q := int(xb[48+32*(j/2)+i])
				if j%2 == 0 {
					q &= 0xf
				} else {
					q >>= 4
				}
				if xb[16+i]&(1<<j) != 0 {
					q += 16
				}
				wv := f16val(d)*float64(sc)*float64(q) - f16val(dmin)*float64(m)
				want += wv * yv[b*256+32*j+i]
			}
		}
	}
	return x, y, want
}

func runQ5_K(t *testing.T, kernel dotKernel, n int) {
	t.Helper()
	x, y, want := genQ5_K(n, uint32(n)*2654435761+7)
	if got := callDot(t, kernel, n, x, y); !close32(got, want, 2e-5) {
		t.Fatalf("q5_K n=%d dot = %v, want %v", n, got, want)
	}
}

func runQ5_KTile(t *testing.T, kernel dotKernel, n int) {
	runTile(t, "q5_K", kernel, n, genQ5_K)
	runTileExact(t, "q5_K", kernel, n, genQ5_K)
}
`

const q5KDecls = "\nfunc Q5KKernel(m *mockModule, l0 int32, l1, l2, l3, l4, l5, l6 int64, l7 int32)\nfunc trapstub()\n\nvar _ = trapstub\n"

const q5KRunTest = `package quantrun

import "testing"

func TestQ5K(t *testing.T) {
	for _, n := range []int{256, 512, 1024, 2048} {
		runQ5_K(t, Q5KKernel, n)
		runQ5_KTile(t, Q5KKernel, n)
	}
}
`

func TestA64VecDotQ5KKernelGate(t *testing.T) {
	_, argBytes := vecDotArgs(true)
	asm := wrap("arm64", "Q5KKernel", 16, argBytes, "dotprod", a64VecDotQ5_KKernel("Q5KKernel", nil, true))
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "arm64", asm, quantRunCommon+kQuantRunSrc+q5KRunSrc+q5KDecls, q5KRunTest)
	runArm64Gate(t, dir, ".", "TestQ5K", asm)
}

func TestX64VecDotQ5KKernelGate(t *testing.T) {
	_, argBytes := vecDotArgs(true)
	pool := NewConstPool("q5kx_")
	asm := wrap("amd64", "Q5KKernel", 16, argBytes, "avx2", x64VecDotQ5_KKernel("Q5KKernel", pool, true)+"\n"+pool.Emit())
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "amd64", asm, quantRunCommon+kQuantRunSrc+q5KRunSrc+q5KDecls, q5KRunTest)
	runAmd64Gate(t, dir, ".", "TestQ5K", asm)
}
