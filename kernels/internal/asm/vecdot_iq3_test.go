package asm

import (
	"encoding/binary"
	"fmt"
	"strings"
	"testing"
)

func TestVecDotIQ3KernelShape(t *testing.T) {
	a := a64VecDotIQ3XXSKernel("Fni3xdotprod", NewConstPool("t_"), true)
	for _, want := range []string{"UBFX\t$56, R5, $8, R7", "MOVWU\t(R12)(R7<<2), R8", "mov v3.s[3], w8", "UBFX\t$21, R6, $7, R7", "MOVD\t(R13)(R7<<3), R8", "mov v5.d[1], x8", "mul v2.16b, v2.16b, v4.16b", "sdot v12.4s, v2.16b, v6.16b", "LSRW\t$28, R6, R7", "fmul s22, s22, s17", "i3xblk:"} {
		if !strings.Contains(a, want) {
			t.Errorf("a64 iq3_xxs dot missing %q", want)
		}
	}
	b := a64VecDotIQ3SKernel("Fni3sdotprod", NewConstPool("t_"), true)
	for _, want := range []string{"UBFX\t$7, R6, $1, R8", "ORR\tR8<<8, R7, R7", "mov v24.s[0], w9", "tbl v4.16b, {v24.16b}, v19.16b", "cmtst v4.16b, v4.16b, v18.16b", "orr v4.16b, v4.16b, v23.16b", "MOVBU\t109(R3), R7", "i3sblk:"} {
		if !strings.Contains(b, want) {
			t.Errorf("a64 iq3_s dot missing %q", want)
		}
	}
	c := iq3xxsConsts()
	if len(c) != 2048 || binary.LittleEndian.Uint32(c[0:]) != 0x04040404 || c[1024] != 1 || c[1024+8] != 0xff || c[1024+8+7] != 0xff || c[1024+8+1] != 1 {
		t.Errorf("iq3_xxs const blob: grid[0] %#x, signs[0] %v, signs[1] %v", binary.LittleEndian.Uint32(c[0:]), c[1024:1032], c[1032:1040])
	}
	x := x64VecDotIQ3XXSKernel("Fni3xavx2", NewConstPool("t_"), true)
	for _, want := range []string{"MOVL\t(R12)(R14*4), R15", "VPINSRD\t$3, R15, X5, X5", "MOVQ\t(R13)(R14*8), R15", "VPINSRQ\t$1, R15, X7, X7", "VPSIGNB\tY4, Y3, Y3", "VPMADDUBSW\tY3, Y2, Y5", "SHRL\t$28, R8", "MOVL\t$0x3E800000, R8"} {
		if !strings.Contains(x, want) {
			t.Errorf("x64 iq3_xxs dot missing %q", want)
		}
	}
	xs := x64VecDotIQ3SKernel("Fni3savx2", NewConstPool("t_"), true)
	for _, want := range []string{"VPSHUFB\tY11, Y4, Y4", "VPCMPEQB\tY12, Y4, Y4", "VPOR\tY13, Y4, Y4", "MOVBLZX\t109(SI), R8", "SHLL\t$8, R11"} {
		if !strings.Contains(xs, want) {
			t.Errorf("x64 iq3_s dot missing %q", want)
		}
	}
	if d := iq3sConsts(); len(d) != 2096 || binary.LittleEndian.Uint32(d[0:]) != 0x01010101 || d[2048+8] != 1 || d[2064] != 2 || d[2080+7] != 128 {
		t.Errorf("iq3_s const blob")
	}
}

// iq3RunSrc: random iq3_xxs / iq3_s blocks against a float64 reference
// that follows the generic bodies. The codebooks are emitted into the run
// tree as Go tables.
var iq3RunSrc = fmt.Sprintf(`
var iq3xxsGridT = %s
var iq3sGridT = %s
var ksignsT = %s

func genIQ3XXS(n int, seed uint32) ([]byte, []byte, float64) {
	nb := n / 256
	s := lcg(seed)
	x := make([]byte, nb*98)
	y := make([]byte, nb*292)
	var want float64
	for b := 0; b < nb; b++ {
		xb, yb := x[b*98:], y[b*292:]
		d := f16bits(s.scale())
		put16(xb, 0, d)
		for i := 2; i < 98; i++ {
			xb[i] = s.byte_()
		}
		yd := float32(int32(s.next()>>8)%%200+1) / 64
		put32(yb, 0, yd)
		for i := 0; i < 256; i++ {
			yb[4+i] = byte(s.i8())
		}
		bsum := 0
		for ib := 0; ib < 8; ib++ {
			aux := uint32(xb[66+4*ib]) | uint32(xb[67+4*ib])<<8 | uint32(xb[68+4*ib])<<16 | uint32(xb[69+4*ib])<<24
			ls := int(2*(aux>>28) + 1)
			sumi := 0
			for l := 0; l < 4; l++ {
				g1 := iq3xxsGridT[xb[2+8*ib+2*l]]
				g2 := iq3xxsGridT[xb[2+8*ib+2*l+1]]
				signs := ksignsT[(aux>>(7*l))&127]
				for j := 0; j < 4; j++ {
					q8 := yb[4+32*ib+8*l:]
					s1, s2 := 1, 1
					if signs&(1<<j) != 0 {
						s1 = -1
					}
					if signs&(1<<(j+4)) != 0 {
						s2 = -1
					}
					sumi += int(g1>>(8*j)&0xff) * int(int8(q8[j])) * s1
					sumi += int(g2>>(8*j)&0xff) * int(int8(q8[j+4])) * s2
				}
			}
			bsum += sumi * ls
		}
		want += 0.25 * f16val(d) * float64(yd) * float64(bsum)
	}
	return x, y, want
}

func genIQ3S(n int, seed uint32) ([]byte, []byte, float64) {
	nb := n / 256
	s := lcg(seed)
	x := make([]byte, nb*110)
	y := make([]byte, nb*292)
	var want float64
	for b := 0; b < nb; b++ {
		xb, yb := x[b*110:], y[b*292:]
		d := f16bits(s.scale())
		put16(xb, 0, d)
		for i := 2; i < 110; i++ {
			xb[i] = s.byte_()
		}
		yd := float32(int32(s.next()>>8)%%200+1) / 64
		put32(yb, 0, yd)
		for i := 0; i < 256; i++ {
			yb[4+i] = byte(s.i8())
		}
		bsum := 0
		for ib := 0; ib < 8; ib++ {
			sc := xb[106+ib/2]
			var ls int
			if ib%%2 == 0 {
				ls = int(2*(sc&0xf) + 1)
			} else {
				ls = int(2*(sc>>4) + 1)
			}
			qh := uint32(xb[66+ib])
			sumi := 0
			for l := 0; l < 4; l++ {
				i1 := uint32(xb[2+8*ib+2*l]) | ((qh << (8 - 2*uint(l))) & 256)
				i2 := uint32(xb[2+8*ib+2*l+1]) | ((qh << (7 - 2*uint(l))) & 256)
				g1, g2 := iq3sGridT[i1], iq3sGridT[i2]
				signs := xb[74+4*ib+l]
				q8 := yb[4+32*ib+8*l:]
				for j := 0; j < 4; j++ {
					s1, s2 := 1, 1
					if signs&(1<<j) != 0 {
						s1 = -1
					}
					if signs&(1<<(j+4)) != 0 {
						s2 = -1
					}
					sumi += int(g1>>(8*j)&0xff) * int(int8(q8[j])) * s1
					sumi += int(g2>>(8*j)&0xff) * int(int8(q8[j+4])) * s2
				}
			}
			bsum += sumi * ls
		}
		want += f16val(d) * float64(yd) * float64(bsum)
	}
	return x, y, want
}

func runIQ3XXS(t *testing.T, kernel dotKernel, n int) {
	t.Helper()
	x, y, want := genIQ3XXS(n, uint32(n)*2654435761+31)
	if got := callDot(t, kernel, n, x, y); !close32(got, want, 1e-5) {
		t.Fatalf("iq3_xxs n=%%d dot = %%v, want %%v", n, got, want)
	}
}

func runIQ3S(t *testing.T, kernel dotKernel, n int) {
	t.Helper()
	x, y, want := genIQ3S(n, uint32(n)*2654435761+37)
	if got := callDot(t, kernel, n, x, y); !close32(got, want, 1e-5) {
		t.Fatalf("iq3_s n=%%d dot = %%v, want %%v", n, got, want)
	}
}
`, goTable32(iq3xxsGrid[:]), goTable32(iq3sGrid[:]), goTable8(ksignsIQ2XS[:]))

// goTable32 / goTable8 render a table as a Go array literal for the run tree.
func goTable32(v []uint32) string {
	var sb strings.Builder
	fmt.Fprintf(&sb, "[%d]uint32{", len(v))
	for i, x := range v {
		if i%8 == 0 {
			sb.WriteString("\n\t")
		}
		fmt.Fprintf(&sb, "%#x, ", x)
	}
	sb.WriteString("\n}")
	return sb.String()
}

func goTable8(v []uint8) string {
	var sb strings.Builder
	fmt.Fprintf(&sb, "[%d]uint8{", len(v))
	for i, x := range v {
		if i%16 == 0 {
			sb.WriteString("\n\t")
		}
		fmt.Fprintf(&sb, "%d, ", x)
	}
	sb.WriteString("\n}")
	return sb.String()
}

const iq3Decls = "\nfunc I3XKernel(m *mockModule, l0 int32, l1, l2, l3, l4, l5, l6 int64, l7 int32)\nfunc I3SKernel(m *mockModule, l0 int32, l1, l2, l3, l4, l5, l6 int64, l7 int32)\nfunc trapstub()\n\nvar _ = trapstub\n"

const iq3RunTest = `package quantrun

import "testing"

func TestIQ3(t *testing.T) {
	for _, n := range []int{256, 512, 0, 768, 1536, 4864} {
		runIQ3XXS(t, I3XKernel, n)
		runIQ3S(t, I3SKernel, n)
	}
}
`

func TestA64VecDotIQ3KernelGate(t *testing.T) {
	_, argBytes := vecDotArgs(true)
	pool := NewConstPool("i3_")
	asm := wrap("arm64", "I3XKernel", 16, argBytes, "dotprod", a64VecDotIQ3XXSKernel("I3XKernel", pool, true)) +
		wrap("arm64", "I3SKernel", 16, argBytes, "dotprod", a64VecDotIQ3SKernel("I3SKernel", pool, true)) + pool.Emit()
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "arm64", asm, quantRunCommon+iq3RunSrc+iq3Decls, iq3RunTest)
	runArm64Gate(t, dir, ".", "TestIQ3", asm)
}

func TestX64VecDotIQ3KernelGate(t *testing.T) {
	_, argBytes := vecDotArgs(true)
	pool := NewConstPool("i3x_")
	asm := wrap("amd64", "I3XKernel", 16, argBytes, "avx2", x64VecDotIQ3XXSKernel("I3XKernel", pool, true)) +
		wrap("amd64", "I3SKernel", 16, argBytes, "avx2", x64VecDotIQ3SKernel("I3SKernel", pool, true)) + pool.Emit()
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "amd64", asm, quantRunCommon+iq3RunSrc+iq3Decls, iq3RunTest)
	runAmd64Gate(t, dir, ".", "TestIQ3", asm)
}
