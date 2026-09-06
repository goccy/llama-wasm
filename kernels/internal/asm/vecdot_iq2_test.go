package asm

import (
	"encoding/binary"
	"fmt"
	"strings"
	"testing"
)

func TestVecDotIQ2KernelShape(t *testing.T) {
	a := a64VecDotIQ2XXSKernel("Fni2xdotprod", NewConstPool("t_"), true)
	for _, want := range []string{"UBFX\t$24, R5, $8, R7", "MOVD\t(R12)(R7<<3), R8", "mov v3.d[1], x8", "UBFX\t$53, R5, $7, R7", "LSR\t$60, R5, R7", "i2xblk:", "ADD\t$2048, R12, R13"} {
		if !strings.Contains(a, want) {
			t.Errorf("a64 iq2_xxs dot missing %q", want)
		}
	}
	b := a64VecDotIQ2XSKernel("Fni2sdotprod", NewConstPool("t_"), true)
	for _, want := range []string{"UBFX\t$48, R5, $9, R7", "UBFX\t$57, R5, $7, R7", "MOVBU\t73(R3), R7", "mla v20.4s, v13.4s, v21.4s", "ADD\t$4096, R12, R13"} {
		if !strings.Contains(b, want) {
			t.Errorf("a64 iq2_xs dot missing %q", want)
		}
	}
	c := a64VecDotIQ2SKernel("Fni2tdotprod", NewConstPool("t_"), true)
	for _, want := range []string{"UBFX\t$6, R6, $2, R8", "ORR\tR8<<8, R7, R7", "MOVWU\t62(R3), R9", "tbl v5.16b, {v24.16b}, v22.16b", "MOVBU\t81(R3), R7", "ADD\t$8192, R12, R13"} {
		if !strings.Contains(c, want) {
			t.Errorf("a64 iq2_s dot missing %q", want)
		}
	}
	x := x64VecDotIQ2XSKernel("Fni2savx2", NewConstPool("t_"), true)
	for _, want := range []string{"ANDL\t$511, R14", "MOVQ\t(R12)(R14*8), R15", "VPINSRQ\t$1, R15, X5, X5", "SHRL\t$9, R8", "VINSERTI128\t$1, X7, Y6, Y6", "MOVL\t$0x3E000000, R8", "LEAQ\t4096(R12), R13"} {
		if !strings.Contains(x, want) {
			t.Errorf("x64 iq2_xs dot missing %q", want)
		}
	}
	if k := iq2Consts(iq2xxsL); len(k) != 2048+1024 || binary.LittleEndian.Uint64(k[8:]) != iq2xxsGrid[1] || k[2048+8] != 0xff {
		t.Errorf("iq2_xxs const blob")
	}
	if k := iq2Consts(iq2sL); len(k) != 8192+48 || k[8192+8] != 1 || k[8192+32+7] != 128 {
		t.Errorf("iq2_s const blob")
	}
}

// iq2RunSrc: random blocks of the three formats against float64 references
// following the generic bodies.
var iq2RunSrc = fmt.Sprintf(`
var iq2xxsGridT = %s
var iq2xsGridT = %s
var iq2sGridT = %s
var ksigns2T = %s

func signedSum(grid uint64, signs byte, q8 []byte) int {
	sum := 0
	for j := 0; j < 8; j++ {
		v := int(grid >> (8 * uint(j)) & 0xff)
		if signs&(1<<uint(j)) != 0 {
			v = -v
		}
		sum += v * int(int8(q8[j]))
	}
	return sum
}

func genIQ2(kind string, n int, seed uint32) ([]byte, []byte, float64) {
	nb := n / 256
	bb := map[string]int{"iq2_xxs": 66, "iq2_xs": 74, "iq2_s": 82}[kind]
	s := lcg(seed)
	x := make([]byte, nb*bb)
	y := make([]byte, nb*292)
	var want float64
	for b := 0; b < nb; b++ {
		xb, yb := x[b*bb:], y[b*292:]
		d := f16bits(s.scale())
		put16(xb, 0, d)
		for i := 2; i < bb; i++ {
			xb[i] = s.byte_()
		}
		yd := float32(int32(s.next()>>8)%%200+1) / 64
		put32(yb, 0, yd)
		for i := 0; i < 256; i++ {
			yb[4+i] = byte(s.i8())
		}
		bsum := 0
		for ib := 0; ib < 8; ib++ {
			q8 := yb[4+32*ib:]
			switch kind {
			case "iq2_xxs":
				aux1 := uint32(xb[6+8*ib]) | uint32(xb[7+8*ib])<<8 | uint32(xb[8+8*ib])<<16 | uint32(xb[9+8*ib])<<24
				ls := int(2*(aux1>>28) + 1)
				sumi := 0
				for l := 0; l < 4; l++ {
					sumi += signedSum(iq2xxsGridT[xb[2+8*ib+l]], ksigns2T[(aux1>>(7*uint(l)))&127], q8[8*l:])
				}
				bsum += sumi * ls
			case "iq2_xs":
				sc := xb[66+ib]
				ls1, ls2 := int(2*(sc&0xf)+1), int(2*(sc>>4)+1)
				sumi1, sumi2 := 0, 0
				for l := 0; l < 4; l++ {
					q2 := uint16(xb[2+8*ib+2*l]) | uint16(xb[3+8*ib+2*l])<<8
					v := signedSum(iq2xsGridT[q2&511], ksigns2T[q2>>9], q8[8*l:])
					if l < 2 {
						sumi1 += v
					} else {
						sumi2 += v
					}
				}
				bsum += sumi1*ls1 + sumi2*ls2
			default:
				sc := xb[74+ib]
				ls1, ls2 := int(2*(sc&0xf)+1), int(2*(sc>>4)+1)
				qh := uint32(xb[66+ib])
				sumi1, sumi2 := 0, 0
				for l := 0; l < 4; l++ {
					idx := uint32(xb[2+4*ib+l]) | ((qh << (8 - 2*uint(l))) & 0x300)
					v := signedSum(iq2sGridT[idx], xb[34+4*ib+l], q8[8*l:])
					if l < 2 {
						sumi1 += v
					} else {
						sumi2 += v
					}
				}
				bsum += sumi1*ls1 + sumi2*ls2
			}
		}
		want += 0.125 * f16val(d) * float64(yd) * float64(bsum)
	}
	return x, y, want
}

func runIQ2(t *testing.T, kind string, kernel dotKernel, n int) {
	t.Helper()
	x, y, want := genIQ2(kind, n, uint32(n)*2654435761+uint32(len(kind)))
	if got := callDot(t, kernel, n, x, y); !close32(got, want, 1e-5) {
		t.Fatalf("%%s n=%%d dot = %%v, want %%v", kind, n, got, want)
	}
}
`, goTable64(iq2xxsGrid[:]), goTable64(iq2xsGrid[:]), goTable64(iq2sGrid[:]), goTable8(ksignsIQ2XS[:]))

func goTable64(v []uint64) string {
	var sb strings.Builder
	fmt.Fprintf(&sb, "[%d]uint64{", len(v))
	for i, x := range v {
		if i%4 == 0 {
			sb.WriteString("\n\t")
		}
		fmt.Fprintf(&sb, "%#x, ", x)
	}
	sb.WriteString("\n}")
	return sb.String()
}

const iq2Decls = "\nfunc I2XKernel(m *mockModule, l0 int32, l1, l2, l3, l4, l5, l6 int64, l7 int32)\nfunc I2SKernel(m *mockModule, l0 int32, l1, l2, l3, l4, l5, l6 int64, l7 int32)\nfunc I2TKernel(m *mockModule, l0 int32, l1, l2, l3, l4, l5, l6 int64, l7 int32)\nfunc trapstub()\n\nvar _ = trapstub\n"

const iq2RunTest = `package quantrun

import "testing"

func TestIQ2(t *testing.T) {
	for _, n := range []int{256, 512, 0, 768, 1536, 4864} {
		runIQ2(t, "iq2_xxs", I2XKernel, n)
		runIQ2(t, "iq2_xs", I2SKernel, n)
		runIQ2(t, "iq2_s", I2TKernel, n)
	}
}
`

func TestA64VecDotIQ2KernelGate(t *testing.T) {
	_, argBytes := vecDotArgs(true)
	pool := NewConstPool("i2_")
	asm := wrap("arm64", "I2XKernel", 16, argBytes, "dotprod", a64VecDotIQ2XXSKernel("I2XKernel", pool, true)) +
		wrap("arm64", "I2SKernel", 16, argBytes, "dotprod", a64VecDotIQ2XSKernel("I2SKernel", pool, true)) +
		wrap("arm64", "I2TKernel", 16, argBytes, "dotprod", a64VecDotIQ2SKernel("I2TKernel", pool, true)) + pool.Emit()
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "arm64", asm, quantRunCommon+iq2RunSrc+iq2Decls, iq2RunTest)
	runArm64Gate(t, dir, ".", "TestIQ2", asm)
}

func TestX64VecDotIQ2KernelGate(t *testing.T) {
	_, argBytes := vecDotArgs(true)
	pool := NewConstPool("i2x_")
	asm := wrap("amd64", "I2XKernel", 16, argBytes, "avx2", x64VecDotIQ2XXSKernel("I2XKernel", pool, true)) +
		wrap("amd64", "I2SKernel", 16, argBytes, "avx2", x64VecDotIQ2XSKernel("I2SKernel", pool, true)) +
		wrap("amd64", "I2TKernel", 16, argBytes, "avx2", x64VecDotIQ2SKernel("I2TKernel", pool, true)) + pool.Emit()
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "amd64", asm, quantRunCommon+iq2RunSrc+iq2Decls, iq2RunTest)
	runAmd64Gate(t, dir, ".", "TestIQ2", asm)
}
