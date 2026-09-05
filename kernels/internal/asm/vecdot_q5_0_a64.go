package asm

import "strings"

// q5_0 x q8_0 dot (ggml_vec_dot_q5_0_q8_0). The wasm body widens each
// nibble pair through the i16 dot and gathers the fifth bits through a
// table; here the fifth bits come from a TBL/CMTST pair and the
// products from SDOT, two blocks per step like the arm64 llama.cpp
// version. FastMath only: per-block f32 fused accumulate where the
// wasm keeps a multiply then add.
//
// Block layouts (bytes): q5_0 = d f16 (0) | qh u32 (2) | qs 16 nibble
// pairs (6), 22 total; q8_0 = d f16 (0) | qs 32 i8 (2), 34 total. Low
// nibble j and bit j of qh make quant j (0..15); the high nibbles and
// bits 16..31 make quants 16..31. Each quant is (nibble | bit<<4) - 16.

const (
	q5_0BlockBytes = 22
	q8_0BlockBytes = 34
)

// q5_0Consts is the constant blob: two TBL index vectors that spread
// qh's bytes 0/1 and 2/3 over the 16 lanes, then the per-lane bit
// masks 1<<(lane%8).
func q5_0Consts() []byte {
	c := make([]byte, 48)
	for i := 0; i < 16; i++ {
		c[i] = byte(i / 8)
		c[16+i] = byte(2 + i/8)
		c[32+i] = 1 << (i % 8)
	}
	return c
}

// a64VecDotQ5_0Kernel emits the kernel under sym. Registers: R1 nb,
// R2 s, R3 x, R4 y; v0/v1 the two f32 accumulators; v16 = 0x0f, v17 =
// 16, v18/v19 the TBL indices, v20 the bit masks.
func a64VecDotQ5_0Kernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	e := newA64Q(&sb)
	w := e.w
	cSym := pool.addBlob(q5_0Consts())

	// block emits one q5_0 x q8_0 block at x+xo / y+yo into acc using
	// the temporaries t (10 vector registers).
	block := func(xo, yo, acc int, t [10]int) {
		qs, qh, lo, hi, tlo, thi, ylo, yhi, dot, sc := t[0], t[1], t[2], t[3], t[4], t[5], t[6], t[7], t[8], t[9]
		e.ldurQ(qs, 3, xo+6)
		e.ldurS(qh, 3, xo+2)
		e.ldurQ(ylo, 4, yo+2)
		e.ldurQ(yhi, 4, yo+18)
		e.and16(lo, qs, 16)
		e.ushr16(hi, qs, 4)
		e.tbl16(tlo, qh, 18)
		e.tbl16(thi, qh, 19)
		e.cmtst16(tlo, tlo, 20) // 0xff where the fifth bit is set
		e.cmtst16(thi, thi, 20)
		e.bic16(tlo, 17, tlo) // 16 where it is clear
		e.bic16(thi, 17, thi)
		e.sub16(lo, lo, tlo) // nibble + 16*bit - 16
		e.sub16(hi, hi, thi)
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
	tA := [10]int{2, 4, 6, 8, 10, 12, 14, 21, 23, 25}
	tB := [10]int{3, 5, 7, 9, 11, 13, 15, 22, 24, 26}

	w("// %s: q5_0 x q8_0 dot, two blocks per step via TBL/CMTST fifth bits and SDOT.", sym)
	e.movi4s0(0)
	e.movi4s0(1)
	e.vecDotPrologue(wide, 5, q5_0BlockBytes, q8_0BlockBytes, "q5oob", "q5reduce")
	w("\tMOVD\t$·%s(SB), R5", cSym)
	w("\tVLD1\t(R5), [V18.B16, V19.B16, V20.B16]")
	e.movi16(16, 15)
	e.movi16(17, 16)
	w("q5loop2:")
	w("\tCMPW\t$2, R1")
	w("\tBLT\tq5tail")
	block(0, 0, 0, tA)
	block(q5_0BlockBytes, q8_0BlockBytes, 1, tB)
	w("\tADD\t$%d, R3, R3", 2*q5_0BlockBytes)
	w("\tADD\t$%d, R4, R4", 2*q8_0BlockBytes)
	w("\tSUBW\t$2, R1, R1")
	w("\tB\tq5loop2")
	w("q5tail:")
	w("\tCBZW\tR1, q5reduce")
	block(0, 0, 0, tA)
	w("q5reduce:")
	e.fadd4s(0, 0, 1)
	e.reduceStore(0, 2)
	w("\tRET")
	w("q5oob:")
	w("\tB\tovr_oob")
	return sb.String()
}
