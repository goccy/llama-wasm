package asm

import (
	"math"
	"strings"
	"testing"
)

func TestVecDotTernaryKernelShape(t *testing.T) {
	for name, asm := range map[string]string{
		"tq2_0": a64VecDotTQ2_0Kernel("Fntq2", NewConstPool("t_"), true),
		"tq1_0": a64VecDotTQ1_0Kernel("Fntq1", NewConstPool("t_"), true),
		"q1_0":  a64VecDotQ1_0Kernel("Fnq1", NewConstPool("t_"), true),
		"q2_0":  a64VecDotQ2_0Kernel("Fnq2", NewConstPool("t_"), true),
		"nvfp4": a64VecDotNVFP4Kernel("Fnnv", NewConstPool("t_"), true),
	} {
		if !strings.Contains(asm, "sdot") || !strings.Contains(asm, "ovr_oob") {
			t.Errorf("%s: no dot / no bounds trap", name)
		}
	}
	a := a64VecDotTQ1_0Kernel("Fntq1", NewConstPool("t_"), true)
	for _, want := range []string{"cmhs v4.16b, v2.16b, v16.16b", "cmhs v21.16b, v2.16b, v17.16b", "mvn v4.16b, v4.16b", "mul v2.16b, v2.16b, v18.16b", "ldur s2, [x3, #48]", "ldur h22, [x3, #52]"} {
		if !strings.Contains(a, want) {
			t.Errorf("a64 tq1_0 dot missing %q", want)
		}
	}
	b := a64VecDotQ2_0Kernel("Fnq2", NewConstPool("t_"), true)
	for _, want := range []string{"tbl v4.16b, {v2.16b}, v18.16b", "ushl v4.16b, v4.16b, v19.16b", "ldur h23, [x4, #34]"} {
		if !strings.Contains(b, want) {
			t.Errorf("a64 q2_0 dot missing %q", want)
		}
	}
	if v := ue4m3ToF32(0x38); v != 0.5 { // exp 7, man 0 -> 1.0 * 0.5
		t.Errorf("ue4m3(0x38) = %v, want 0.5", v)
	}
	if v := ue4m3ToF32(0x7f); v != 0 {
		t.Errorf("ue4m3(0x7f) = %v, want 0", v)
	}
	for name, asm := range map[string]string{
		"tq2_0": x64VecDotTQ2_0Kernel("Fntq2", NewConstPool("t_"), true),
		"tq1_0": x64VecDotTQ1_0Kernel("Fntq1", NewConstPool("t_"), true),
		"q1_0":  x64VecDotQ1_0Kernel("Fnq1", NewConstPool("t_"), true),
		"q2_0":  x64VecDotQ2_0Kernel("Fnq2", NewConstPool("t_"), true),
		"nvfp4": x64VecDotNVFP4Kernel("Fnnv", NewConstPool("t_"), true),
	} {
		if !strings.Contains(asm, "VPMADDUBSW") || !strings.Contains(asm, "ovr_oob") {
			t.Errorf("x64 %s: no pair dot / no bounds trap", name)
		}
	}
	x := x64TernaryConsts()
	if len(x) != 352 || x[224+4] != 3 || x[224+5] != 0 || x[224+32+5] != 3 || x[224+96+3] != 3 {
		t.Errorf("x64 ternary const blob")
	}
	c := ternaryConsts()
	if c[16] != 86 || c[32] != 171 || c[80+5] != 1 || int8(c[96+3]) != -6 || c[112] != 3 {
		t.Errorf("ternary const blob")
	}
	n := nvfp4Consts()
	if len(n) != 1040 || math.Float32frombits(uint32(n[0x38*4])|uint32(n[0x38*4+1])<<8|uint32(n[0x38*4+2])<<16|uint32(n[0x38*4+3])<<24) != 0.5 || int8(n[1024+7]) != 12 {
		t.Errorf("nvfp4 const blob")
	}
}

// ternaryRunSrc: references following the generic bodies for the five
// formats; q8_K blocks for tq*, q8_0 blocks for q1_0/q2_0/nvfp4.
const ternaryRunSrc = `
var kvaluesFP4T = [16]int8{0, 1, 2, 3, 4, 6, 8, 12, 0, -1, -2, -3, -4, -6, -8, -12}

func ue4m3(x byte) float64 {
	if x == 0 || x == 0x7f {
		return 0
	}
	exp, man := int(x>>3)&0xf, float64(x&7)
	if exp == 0 {
		return math.Ldexp(man, -9) * 0.5
	}
	return math.Ldexp(1+man/8, exp-7) * 0.5
}

func genQ8K(s *lcg, yb []byte) float32 {
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
	return yd
}

func genTQ2(n int, seed uint32) ([]byte, []byte, float64) {
	nb := n / 256
	s := lcg(seed)
	x := make([]byte, nb*66)
	y := make([]byte, nb*292)
	var want float64
	for b := 0; b < nb; b++ {
		xb, yb := x[b*66:], y[b*292:]
		for i := 0; i < 64; i++ {
			xb[i] = s.byte_()
		}
		d := f16bits(s.scale())
		put16(xb, 64, d)
		yd := genQ8K(&s, yb)
		sumi := 0
		for j := 0; j < 64; j += 32 {
			for l := 0; l < 4; l++ {
				for k := 0; k < 32; k++ {
					sumi += int(int8(yb[4+j*4+l*32+k])) * (int((xb[j+k]>>(2*uint(l)))&3) - 1)
				}
			}
		}
		want += float64(sumi) * f16val(d) * float64(yd)
	}
	return x, y, want
}

func genTQ1(n int, seed uint32) ([]byte, []byte, float64) {
	nb := n / 256
	s := lcg(seed)
	x := make([]byte, nb*54)
	y := make([]byte, nb*292)
	pow3 := [6]int{1, 3, 9, 27, 81, 243}
	var want float64
	for b := 0; b < nb; b++ {
		xb, yb := x[b*54:], y[b*292:]
		for i := 0; i < 52; i++ {
			xb[i] = s.byte_()
		}
		d := f16bits(s.scale())
		put16(xb, 52, d)
		yd := genQ8K(&s, yb)
		sum := 0
		dig := func(q byte, l int) int { return int((uint16(byte(int(q)*pow3[l]))*3)>>8) - 1 }
		for l := 0; l < 5; l++ {
			for m := 0; m < 32; m++ {
				sum += dig(xb[m], l) * int(int8(yb[4+l*32+m]))
			}
		}
		for l := 0; l < 5; l++ {
			for m := 0; m < 16; m++ {
				sum += dig(xb[32+m], l) * int(int8(yb[4+160+l*16+m]))
			}
		}
		for l := 0; l < 4; l++ {
			for j := 0; j < 4; j++ {
				sum += dig(xb[48+j], l) * int(int8(yb[4+240+l*4+j]))
			}
		}
		want += float64(sum) * f16val(d) * float64(yd)
	}
	return x, y, want
}

func genQ1(n int, seed uint32) ([]byte, []byte, float64) {
	nb := n / 128
	s := lcg(seed)
	x := make([]byte, nb*18)
	y := make([]byte, nb*4*34)
	var want float64
	for b := 0; b < nb; b++ {
		xb := x[b*18:]
		d0 := f16bits(s.scale())
		put16(xb, 0, d0)
		for i := 2; i < 18; i++ {
			xb[i] = s.byte_()
		}
		var sumi float64
		for k := 0; k < 4; k++ {
			yb := y[(b*4+k)*34:]
			d1 := f16bits(s.scale())
			put16(yb, 0, d1)
			blk := 0
			for i := 0; i < 32; i++ {
				q := s.i8()
				yb[2+i] = byte(q)
				if xb[2+4*k+i/8]&(1<<uint(i%8)) != 0 {
					blk += int(q)
				} else {
					blk -= int(q)
				}
			}
			sumi += f16val(d1) * float64(blk)
		}
		want += f16val(d0) * sumi
	}
	return x, y, want
}

func genQ2(n int, seed uint32) ([]byte, []byte, float64) {
	nb := n / 64
	s := lcg(seed)
	x := make([]byte, nb*18)
	y := make([]byte, nb*2*34)
	var want float64
	for b := 0; b < nb; b++ {
		xb := x[b*18:]
		d0 := f16bits(s.scale())
		put16(xb, 0, d0)
		for i := 2; i < 18; i++ {
			xb[i] = s.byte_()
		}
		var sumi float64
		for k := 0; k < 2; k++ {
			yb := y[(b*2+k)*34:]
			d1 := f16bits(s.scale())
			put16(yb, 0, d1)
			blk := 0
			for i := 0; i < 32; i++ {
				q := s.i8()
				yb[2+i] = byte(q)
				blk += (int((xb[2+8*k+i/4]>>(2*uint(i%4)))&3) - 1) * int(q)
			}
			sumi += f16val(d1) * float64(blk)
		}
		want += f16val(d0) * sumi
	}
	return x, y, want
}

func genNV(n int, seed uint32) ([]byte, []byte, float64) {
	nb := n / 64
	s := lcg(seed)
	x := make([]byte, nb*36)
	y := make([]byte, nb*2*34)
	var want float64
	for b := 0; b < nb; b++ {
		xb := x[b*36:]
		for i := 0; i < 36; i++ {
			xb[i] = s.byte_()
		}
		for i := 0; i < 4; i++ {
			xb[i] = byte(0x20 + s.next()%0x30) // exponents 4..9: sane scales
		}
		var dy [2]float64
		for k := 0; k < 2; k++ {
			yb := y[(b*2+k)*34:]
			d1 := f16bits(s.scale())
			put16(yb, 0, d1)
			dy[k] = f16val(d1)
			for i := 0; i < 32; i++ {
				yb[2+i] = byte(s.i8())
			}
		}
		for sIdx := 0; sIdx < 4; sIdx++ {
			q8 := sIdx / 2
			off := (sIdx % 2) * 16
			yb := y[(b*2+q8)*34:]
			sumi := 0
			for j := 0; j < 8; j++ {
				qv := xb[4+8*sIdx+j]
				sumi += int(int8(yb[2+off+j]))*int(kvaluesFP4T[qv&0xf]) + int(int8(yb[2+off+8+j]))*int(kvaluesFP4T[qv>>4])
			}
			want += dy[q8] * ue4m3(xb[sIdx]) * float64(sumi)
		}
	}
	return x, y, want
}

func runTernary(t *testing.T, name string, kernel dotKernel, n int, gen func(int, uint32) ([]byte, []byte, float64)) {
	t.Helper()
	x, y, want := gen(n, uint32(n)*2654435761+uint32(len(name)))
	if got := callDot(t, kernel, n, x, y); !close32(got, want, 1e-5) {
		t.Fatalf("%s n=%d dot = %v, want %v", name, n, got, want)
	}
}
`

const ternaryDecls = "\nfunc TQ2Kernel(m *mockModule, l0 int32, l1, l2, l3, l4, l5, l6 int64, l7 int32)\nfunc TQ1Kernel(m *mockModule, l0 int32, l1, l2, l3, l4, l5, l6 int64, l7 int32)\nfunc Q1Kernel(m *mockModule, l0 int32, l1, l2, l3, l4, l5, l6 int64, l7 int32)\nfunc Q2Kernel(m *mockModule, l0 int32, l1, l2, l3, l4, l5, l6 int64, l7 int32)\nfunc NVKernel(m *mockModule, l0 int32, l1, l2, l3, l4, l5, l6 int64, l7 int32)\nfunc trapstub()\n\nvar _ = trapstub\n"

const ternaryRunTest = `package quantrun

import "testing"

func TestTernary(t *testing.T) {
	for _, n := range []int{256, 512, 0, 768, 1536, 4864} {
		runTernary(t, "tq2_0", TQ2Kernel, n, genTQ2)
		runTernary(t, "tq1_0", TQ1Kernel, n, genTQ1)
	}
	for _, n := range []int{128, 256, 0, 896, 4864} {
		runTernary(t, "q1_0", Q1Kernel, n, genQ1)
		runTernary(t, "q2_0", Q2Kernel, n, genQ2)
		runTernary(t, "nvfp4", NVKernel, n, genNV)
	}
}
`

func TestA64VecDotTernaryKernelGate(t *testing.T) {
	_, argBytes := vecDotArgs(true)
	pool := NewConstPool("tn_")
	asm := wrap("arm64", "TQ2Kernel", 16, argBytes, "dotprod", a64VecDotTQ2_0Kernel("TQ2Kernel", pool, true)) +
		wrap("arm64", "TQ1Kernel", 16, argBytes, "dotprod", a64VecDotTQ1_0Kernel("TQ1Kernel", pool, true)) +
		wrap("arm64", "Q1Kernel", 16, argBytes, "dotprod", a64VecDotQ1_0Kernel("Q1Kernel", pool, true)) +
		wrap("arm64", "Q2Kernel", 16, argBytes, "dotprod", a64VecDotQ2_0Kernel("Q2Kernel", pool, true)) +
		wrap("arm64", "NVKernel", 16, argBytes, "dotprod", a64VecDotNVFP4Kernel("NVKernel", pool, true)) + pool.Emit()
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "arm64", asm, quantRunCommon+ternaryRunSrc+ternaryDecls, ternaryRunTest)
	runArm64Gate(t, dir, ".", "TestTernary", asm)
}

func TestX64VecDotTernaryKernelGate(t *testing.T) {
	_, argBytes := vecDotArgs(true)
	pool := NewConstPool("tnx_")
	asm := wrap("amd64", "TQ2Kernel", 16, argBytes, "avx2", x64VecDotTQ2_0Kernel("TQ2Kernel", pool, true)) +
		wrap("amd64", "TQ1Kernel", 16, argBytes, "avx2", x64VecDotTQ1_0Kernel("TQ1Kernel", pool, true)) +
		wrap("amd64", "Q1Kernel", 16, argBytes, "avx2", x64VecDotQ1_0Kernel("Q1Kernel", pool, true)) +
		wrap("amd64", "Q2Kernel", 16, argBytes, "avx2", x64VecDotQ2_0Kernel("Q2Kernel", pool, true)) +
		wrap("amd64", "NVKernel", 16, argBytes, "avx2", x64VecDotNVFP4Kernel("NVKernel", pool, true)) + pool.Emit()
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "amd64", asm, quantRunCommon+ternaryRunSrc+ternaryDecls, ternaryRunTest)
	runAmd64Gate(t, dir, ".", "TestTernary", asm)
}
