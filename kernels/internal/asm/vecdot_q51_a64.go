package asm

import "strings"

// q5_1 x q8_1 and q4_1 x q8_1 dots (ggml_vec_dot_q5_1_q8_1,
// ggml_vec_dot_q4_1_q8_1): the q5_0 structure with unsigned quants (no
// -16 offset: the block min is separate) and the min term m * s added per
// block, s being the activation block's d * sum(q). Two blocks per step
// into two accumulators; the min terms accumulate in a scalar and join at
// the reduction. FastMath only.
//
// Block layouts (bytes): q5_1 = d f16 (0) | m f16 (2) | qh[4] (4) | qs[16]
// (8), 24 total; q4_1 = d (0) | m (2) | qs[16] (4), 20 total; q8_1 = d (0)
// | s f16 (2) | qs[32] (4), 36 total.

const (
	q5_1BlockBytes = 24
	q4_1BlockBytes = 20
	q8_1BlockBytes = 36
)

// a64VecDotQ5_1Kernel emits the q5_1 kernel under sym. Registers: R1 nb,
// R2 s, R3 x, R4 y; v0/v1 the two f32 accumulators, s30 the min terms;
// v16 = 0x0f, v17 = 0x10, v18/v19 the TBL indices, v20 the bit masks.
func a64VecDotQ5_1Kernel(sym string, pool *ConstPool, wide bool) string {
	return a64VecDotQx1Kernel(sym, pool, wide, true)
}

// a64VecDotQ4_1Kernel emits the q4_1 kernel under sym (same registers,
// no fifth bits).
func a64VecDotQ4_1Kernel(sym string, pool *ConstPool, wide bool) string {
	return a64VecDotQx1Kernel(sym, pool, wide, false)
}

func a64VecDotQx1Kernel(sym string, pool *ConstPool, wide bool, fifth bool) string {
	var sb strings.Builder
	e := newA64Q(&sb)
	w := e.w
	name, lbl, xBlock, qsOff := "q4_1", "q41", q4_1BlockBytes, 4
	if fifth {
		name, lbl, xBlock, qsOff = "q5_1", "q51", q5_1BlockBytes, 8
	}
	var cSym string
	if fifth {
		cSym = pool.addBlob(q5_0Consts())
	}

	// block emits one block at x+xo / y+yo into acc using the
	// temporaries t (9 vector registers).
	block := func(xo, yo, acc int, t [9]int) {
		qs, qh, lo, hi, tlo, ylo, yhi, dot, sc := t[0], t[1], t[2], t[3], t[4], t[5], t[6], t[7], t[8]
		e.ldurQ(qs, 3, xo+qsOff)
		e.ldurQ(ylo, 4, yo+4)
		e.ldurQ(yhi, 4, yo+20)
		e.and16(lo, qs, 16)
		e.ushr16(hi, qs, 4)
		if fifth {
			e.ldurS(qh, 3, xo+4)
			e.tbl16(tlo, qh, 18)
			e.cmtst16(tlo, tlo, 20) // 0xff where the fifth bit is set
			e.and16(tlo, tlo, 17)   // 16 there
			e.orr16(lo, lo, tlo)
			e.tbl16(tlo, qh, 19)
			e.cmtst16(tlo, tlo, 20)
			e.and16(tlo, tlo, 17)
			e.orr16(hi, hi, tlo)
		}
		e.movi4s0(dot)
		e.sdot(dot, lo, ylo)
		e.sdot(dot, hi, yhi)
		// d = f16(x.d) * f16(y.d); min term m * s
		e.ldurH(sc, 3, xo)
		e.ldurH(qs, 4, yo)
		e.fcvtSH(sc, sc)
		e.fcvtSH(qs, qs)
		e.fmulS(sc, sc, qs)
		e.scvtf4s(dot, dot)
		e.fmlaLane(acc, dot, sc, 0)
		e.ldurH(sc, 3, xo+2)
		e.ldurH(qs, 4, yo+2)
		e.fcvtSH(sc, sc)
		e.fcvtSH(qs, qs)
		e.fmulS(sc, sc, qs)
		e.faddS(30, 30, sc)
	}
	tA := [9]int{2, 4, 6, 8, 10, 12, 14, 21, 23}
	tB := [9]int{3, 5, 7, 9, 11, 13, 15, 22, 24}

	w("// %s: %s x q8_1 dot, SDOT on unsigned quants plus the block min term, two blocks per step.", sym, name)
	e.movi4s0(0)
	e.movi4s0(1)
	e.movi4s0(30)
	e.vecDotPrologue(wide, 5, xBlock, q8_1BlockBytes, lbl+"oob", lbl+"reduce")
	if fifth {
		w("\tMOVD\t$·%s(SB), R5", cSym)
		w("\tVLD1\t(R5), [V18.B16, V19.B16, V20.B16]")
		e.movi16(17, 16)
	}
	e.movi16(16, 15)
	w("%sloop2:", lbl)
	w("\tCMPW\t$2, R1")
	w("\tBLT\t%stail", lbl)
	block(0, 0, 0, tA)
	block(xBlock, q8_1BlockBytes, 1, tB)
	w("\tADD\t$%d, R3, R3", 2*xBlock)
	w("\tADD\t$%d, R4, R4", 2*q8_1BlockBytes)
	w("\tSUBW\t$2, R1, R1")
	w("\tB\t%sloop2", lbl)
	w("%stail:", lbl)
	w("\tCBZW\tR1, %sreduce", lbl)
	block(0, 0, 0, tA)
	w("%sreduce:", lbl)
	// v0 + v1, plus the min terms in lane 0
	e.fadd4s(0, 0, 1)
	e.movi4s0(31)
	e.insS(31, 0, 30, 0)
	e.fadd4s(0, 0, 31)
	e.reduceStore(0, 2)
	w("\tRET")
	w("%soob:", lbl)
	w("\tB\tovr_oob")
	return sb.String()
}
