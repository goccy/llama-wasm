package asm

import "strings"

// iq4_nl x q8_0 dot (ggml_vec_dot_iq4_nl_q8_0): per 32-quant block the
// nibbles index kvalues_iq4nl (TBL, signed bytes) and two SDOTs against
// the activation block give the integer dot, scaled by f16(x.d) *
// f16(y.d). Two blocks per step into two accumulators. FastMath only.
//
// Block layouts (bytes): iq4_nl = d f16 (0) | qs[16] (2), 18 total;
// q8_0 = d f16 (0) | qs[32] (2), 34 total.

const iq4_nlBlockBytes = 18

// iq4nlConsts: 0: kvalues_iq4nl (16 signed bytes).
func iq4nlConsts() []byte {
	c := make([]byte, 16)
	for i := range kvaluesIQ4NL {
		c[i] = byte(kvaluesIQ4NL[i])
	}
	return c
}

// a64VecDotIQ4NLKernel emits the kernel under sym. Registers: R1 nb,
// R2 s, R3 x, R4 y; v0/v1 the two f32 accumulators; v16 = 0x0f, v18 the
// kvalues table.
func a64VecDotIQ4NLKernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	e := newA64Q(&sb)
	w := e.w
	cSym := pool.addBlob(iq4nlConsts())

	// block emits one iq4_nl x q8_0 block at x+xo / y+yo into acc using
	// the temporaries t (7 vector registers).
	block := func(xo, yo, acc int, t [7]int) {
		qs, lo, hi, ylo, yhi, dot, sc := t[0], t[1], t[2], t[3], t[4], t[5], t[6]
		e.ldurQ(qs, 3, xo+2)
		e.ldurQ(ylo, 4, yo+2)
		e.ldurQ(yhi, 4, yo+18)
		e.and16(lo, qs, 16)
		e.ushr16(hi, qs, 4)
		e.tbl16(lo, 18, lo) // kvalues[nibble]
		e.tbl16(hi, 18, hi)
		e.movi4s0(dot)
		e.sdot(dot, lo, ylo)
		e.sdot(dot, hi, yhi)
		e.ldurH(sc, 3, xo)
		e.ldurH(qs, 4, yo) // qs is free now
		e.fcvtSH(sc, sc)
		e.fcvtSH(qs, qs)
		e.fmulS(sc, sc, qs)
		e.scvtf4s(dot, dot)
		e.fmlaLane(acc, dot, sc, 0)
	}
	tA := [7]int{2, 4, 6, 8, 10, 12, 14}
	tB := [7]int{3, 5, 7, 9, 11, 13, 15}

	w("// %s: iq4_nl x q8_0 dot, TBL kvalues lookup and SDOT, two blocks per step.", sym)
	e.movi4s0(0)
	e.movi4s0(1)
	e.vecDotPrologue(wide, 5, iq4_nlBlockBytes, q8_0BlockBytes, "iq4oob", "iq4reduce")
	w("\tMOVD\t$·%s(SB), R5", cSym)
	e.ldurQ(18, 5, 0)
	e.movi16(16, 15)
	w("iq4loop2:")
	w("\tCMPW\t$2, R1")
	w("\tBLT\tiq4tail")
	block(0, 0, 0, tA)
	block(iq4_nlBlockBytes, q8_0BlockBytes, 1, tB)
	w("\tADD\t$%d, R3, R3", 2*iq4_nlBlockBytes)
	w("\tADD\t$%d, R4, R4", 2*q8_0BlockBytes)
	w("\tSUBW\t$2, R1, R1")
	w("\tB\tiq4loop2")
	w("iq4tail:")
	w("\tCBZW\tR1, iq4reduce")
	block(0, 0, 0, tA)
	w("iq4reduce:")
	e.fadd4s(0, 0, 1)
	e.reduceStore(0, 2)
	w("\tRET")
	w("iq4oob:")
	w("\tB\tovr_oob")
	return sb.String()
}
