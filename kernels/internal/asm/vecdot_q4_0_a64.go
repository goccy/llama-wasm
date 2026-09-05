package asm

import "strings"

// q4_0 x q8_0 and q8_0 x q8_0 dots (ggml_vec_dot_q4_0_q8_0,
// ggml_vec_dot_q8_0_q8_0): the per-row path of the legacy 4- and 8-bit
// types when a tensor is not repacked (a shared token embedding used as
// the output projection, rows not a multiple of the repack width).
// Block layouts (bytes): q4_0 = d f16 (0) | qs 16 nibble pairs (2), 18
// total, quant j = nibble - 8 (low nibbles quants 0..15, high 16..31);
// q8_0 = d f16 (0) | qs 32 i8 (2), 34 total. Like a64VecDotQ5_0Kernel:
// SDOT over the 32 products, two blocks per step into two f32
// accumulators, per-block fused accumulate.

const q4_0BlockBytes = 18

// a64VecDotQ4_0Kernel emits the q4_0 x q8_0 dot under sym. Registers:
// R1 nb, R2 s, R3 x, R4 y; v0/v1 the two f32 accumulators; v16 = 0x0f,
// v17 = 8.
func a64VecDotQ4_0Kernel(sym string, pool *ConstPool, wide bool) string {
	return a64VecDotLegacy(sym, wide, "q4_0", q4_0BlockBytes)
}

// a64VecDotQ8_0Kernel emits the q8_0 x q8_0 dot under sym (same
// register plan, no unpacking).
func a64VecDotQ8_0Kernel(sym string, pool *ConstPool, wide bool) string {
	return a64VecDotLegacy(sym, wide, "q8_0", q8_0BlockBytes)
}

func a64VecDotLegacy(sym string, wide bool, kind string, xBlock int) string {
	var sb strings.Builder
	e := newA64Q(&sb)
	w := e.w
	lbl := "q4d"
	if kind == "q8_0" {
		lbl = "q8d"
	}
	// block emits one block at x+xo / y+yo into acc using the
	// temporaries t (7 vector registers).
	block := func(xo, yo, acc int, t [7]int) {
		lo, hi, ylo, yhi, dot, sc, yd := t[0], t[1], t[2], t[3], t[4], t[5], t[6]
		if kind == "q8_0" {
			e.ldurQ(lo, 3, xo+2)
			e.ldurQ(hi, 3, xo+18)
		} else {
			e.ldurQ(lo, 3, xo+2)
			e.ushr16(hi, lo, 4)
			e.and16(lo, lo, 16)
			e.sub16(lo, lo, 17) // nibble - 8
			e.sub16(hi, hi, 17)
		}
		e.ldurQ(ylo, 4, yo+2)
		e.ldurQ(yhi, 4, yo+18)
		e.movi4s0(dot)
		e.sdot(dot, lo, ylo)
		e.sdot(dot, hi, yhi)
		e.ldurH(sc, 3, xo)
		e.ldurH(yd, 4, yo)
		e.fcvtSH(sc, sc)
		e.fcvtSH(yd, yd)
		e.fmulS(sc, sc, yd)
		e.scvtf4s(dot, dot)
		e.fmlaLane(acc, dot, sc, 0)
	}
	tA := [7]int{2, 4, 6, 8, 10, 12, 14}
	tB := [7]int{3, 5, 7, 9, 11, 13, 15}

	w("// %s: %s x q8_0 dot, two blocks per step via SDOT.", sym, kind)
	e.movi4s0(0)
	e.movi4s0(1)
	e.vecDotPrologue(wide, 5, xBlock, q8_0BlockBytes, lbl+"oob", lbl+"reduce")
	if kind != "q8_0" {
		e.movi16(16, 15)
		e.movi16(17, 8)
	}
	w("%sloop2:", lbl)
	w("\tCMPW\t$2, R1")
	w("\tBLT\t%stail", lbl)
	block(0, 0, 0, tA)
	block(xBlock, q8_0BlockBytes, 1, tB)
	w("\tADD\t$%d, R3, R3", 2*xBlock)
	w("\tADD\t$%d, R4, R4", 2*q8_0BlockBytes)
	w("\tSUBW\t$2, R1, R1")
	w("\tB\t%sloop2", lbl)
	w("%stail:", lbl)
	w("\tCBZW\tR1, %sreduce", lbl)
	block(0, 0, 0, tA)
	w("%sreduce:", lbl)
	e.fadd4s(0, 0, 1)
	e.reduceStore(0, 2)
	w("\tRET")
	w("%soob:", lbl)
	w("\tB\tovr_oob")
	return sb.String()
}
