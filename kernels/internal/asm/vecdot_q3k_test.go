package asm

import (
	"strings"
	"testing"
)

func TestVecDotQ3KKernelShape(t *testing.T) {
	a := a64VecDotQ3_KKernel("Fn4dotprod", nil, true)
	for _, want := range []string{"q3kblk:", "q3kzero:", "ovr_oob", "sdot v12.4s", "mla v1.4s", "ldur h25, [x3, #108]", "shl v16.4s, v16.4s, #2"} {
		if !strings.Contains(a, want) {
			t.Errorf("a64 q3_K dot missing %q", want)
		}
	}
	b := x64VecDotQ3_KKernel("Fn4avx2", NewConstPool("q3kt_"), true)
	for _, want := range []string{"q3kblk", "VPMADDUBSW", "VPSUBB", "VPSLLD\t$2, Y13, Y13", "VPMOVSXBW\tX14, Y14"} {
		if !strings.Contains(b, want) {
			t.Errorf("x64 q3_K dot missing %q", want)
		}
	}
}

// q3KRunSrc: plain q3_K rows and their float64 reference dot.
const q3KRunSrc = `
func genQ3_K(n int, seed uint32) ([]byte, []byte, float64) {
	nb := n / 256
	s := lcg(seed)
	x := make([]byte, nb*110)
	y, yv := genQ8_K(&s, nb)
	var want float64
	for b := 0; b < nb; b++ {
		xb := x[b*110:]
		for i := 0; i < 108; i++ {
			xb[i] = s.byte_()
		}
		d := f16bits(s.scale() / 4)
		put16(xb, 108, d)
		// scales: the kmask unpack, then -32
		aux := [3]uint32{}
		for i := 0; i < 3; i++ {
			aux[i] = uint32(xb[96+4*i]) | uint32(xb[97+4*i])<<8 | uint32(xb[98+4*i])<<16 | uint32(xb[99+4*i])<<24
		}
		const k1, k2 = 0x03030303, 0x0f0f0f0f
		utmp := [4]uint32{
			(aux[0] & k2) | (((aux[2] >> 0) & k1) << 4),
			(aux[1] & k2) | (((aux[2] >> 2) & k1) << 4),
			((aux[0] >> 4) & k2) | (((aux[2] >> 4) & k1) << 4),
			((aux[1] >> 4) & k2) | (((aux[2] >> 6) & k1) << 4),
		}
		var sc [16]int
		for i := 0; i < 16; i++ {
			sc[i] = int(int8(byte(utmp[i/4]>>(8*(i%4))))) - 32
		}
		for j := 0; j < 2; j++ {
			for sh := 0; sh < 4; sh++ {
				for l := 0; l < 32; l++ {
					is := 8*j + 2*sh + l/16
					q := int((xb[32+32*j+l] >> (2 * sh)) & 3)
					if xb[l]&(1<<(4*j+sh)) == 0 {
						q -= 4
					}
					want += f16val(d) * float64(sc[is]) * float64(q) * yv[b*256+128*j+32*sh+l]
				}
			}
		}
	}
	return x, y, want
}

func runQ3_K(t *testing.T, kernel dotKernel, n int) {
	t.Helper()
	x, y, want := genQ3_K(n, uint32(n)*3266489917+13)
	if got := callDot(t, kernel, n, x, y); !close32(got, want, 2e-5) {
		t.Fatalf("q3_K n=%d dot = %v, want %v", n, got, want)
	}
}
`

const q3KDecls = "\nfunc Q3KKernel(m *mockModule, l0 int32, l1, l2, l3, l4, l5, l6 int64, l7 int32)\nfunc trapstub()\n\nvar _ = trapstub\n"

const q3KRunTest = `package quantrun

import "testing"

func TestQ3K(t *testing.T) {
	for _, n := range []int{256, 512, 1024, 2048} {
		runQ3_K(t, Q3KKernel, n)
	}
}
`

func TestA64VecDotQ3KKernelGate(t *testing.T) {
	_, argBytes := vecDotArgs(true)
	asm := wrap("arm64", "Q3KKernel", 16, argBytes, "dotprod", a64VecDotQ3_KKernel("Q3KKernel", nil, true))
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "arm64", asm, quantRunCommon+kQuantRunSrc+q3KRunSrc+q3KDecls, q3KRunTest)
	runArm64Gate(t, dir, ".", "TestQ3K", asm)
}

func TestX64VecDotQ3KKernelGate(t *testing.T) {
	_, argBytes := vecDotArgs(true)
	pool := NewConstPool("q3kx_")
	asm := wrap("amd64", "Q3KKernel", 16, argBytes, "avx2", x64VecDotQ3_KKernel("Q3KKernel", pool, true)+"\n"+pool.Emit())
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "amd64", asm, quantRunCommon+kQuantRunSrc+q3KRunSrc+q3KDecls, q3KRunTest)
	runAmd64Gate(t, dir, ".", "TestQ3K", asm)
}
