package asm

import "strings"

// iq4_xs x q8_K dot (ggml_vec_dot_iq4_xs_q8_K): a 256-quant super-block
// of eight 32-quant sub-blocks whose nibbles index kvalues_iq4nl (TBL)
// and whose 6-bit scales (low nibble in scales_l, two high bits in
// scales_h) are integers applied to the sub-block's i32 dot; the block's
// f16 d times the activation block's f32 d scales the i32 total once.
// Same integer-accumulate order as llama.cpp's NEON body. FastMath only.
//
// Block layouts (bytes): iq4_xs = d f16 (0) | scales_h u16 (2) |
// scales_l[4] (4) | qs[128] (8), 136 total; q8_K = d f32 (0) | qs[256]
// (4) | bsums[16] i16 (260), 292 total.

const iq4_xsBlockBytes = 136

// a64VecDotIQ4XSKernel emits the kernel under sym. Registers: R1 nb,
// R2 s, R3 x, R4 y, R5 scales_h (shifted per pair), R6 scales_l, R7/R8
// scale scratch; v0 the f32 accumulator, v16 = 0x0f, v18 the kvalues
// table, v20 the super-block's i32 sum, v21 the broadcast scale.
func a64VecDotIQ4XSKernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	e := newA64Q(&sb)
	w := e.w
	cSym := pool.addBlob(iq4nlConsts())

	w("// %s: iq4_xs x q8_K dot, TBL kvalues lookup, SDOT per sub-block, 6-bit scales as i32 lane multiplies.", sym)
	e.movi4s0(0)
	e.vecDotPrologue(wide, 8, iq4_xsBlockBytes, q8_KBlockBytes, "ixoob", "ixreduce")
	w("\tMOVD\t$·%s(SB), R7", cSym)
	w("\tVLD1\t(R7), [V18.B16]")
	e.movi16(16, 15)
	w("ixblk:")
	e.movi4s0(20)
	w("\tMOVHU\t2(R3), R5") // scales_h
	w("\tMOVWU\t4(R3), R6") // scales_l[0..3]
	for p := 0; p < 4; p++ {
		xo := 8 + 32*p
		yo := 4 + 64*p
		e.ldurQ(2, 3, xo)
		e.ldurQ(3, 3, xo+16)
		e.ldurQ(8, 4, yo)
		e.ldurQ(9, 4, yo+16)
		e.ldurQ(10, 4, yo+32)
		e.ldurQ(11, 4, yo+48)
		e.and16(4, 2, 16)
		e.ushr16(5, 2, 4)
		e.and16(6, 3, 16)
		e.ushr16(7, 3, 4)
		e.tbl16(4, 18, 4)
		e.tbl16(5, 18, 5)
		e.tbl16(6, 18, 6)
		e.tbl16(7, 18, 7)
		e.movi4s0(12)
		e.sdot(12, 4, 8)
		e.sdot(12, 5, 9) // sub-block 2p
		e.movi4s0(13)
		e.sdot(13, 6, 10)
		e.sdot(13, 7, 11) // sub-block 2p+1
		// ls1 = (sl & 0xf | (h << 4) & 0x30) - 32; ls2 = (sl >> 4 & 0xf | (h << 2) & 0x30) - 32
		w("\tANDW\t$0xf, R6, R7")
		w("\tLSLW\t$4, R5, R8")
		w("\tANDW\t$0x30, R8, R8")
		w("\tORRW\tR8, R7, R7")
		w("\tSUBW\t$32, R7, R7")
		e.dup4sW(21, 7)
		e.mla4s(20, 12, 21)
		w("\tLSRW\t$4, R6, R7")
		w("\tANDW\t$0xf, R7, R7")
		w("\tLSLW\t$2, R5, R8")
		w("\tANDW\t$0x30, R8, R8")
		w("\tORRW\tR8, R7, R7")
		w("\tSUBW\t$32, R7, R7")
		e.dup4sW(21, 7)
		e.mla4s(20, 13, 21)
		if p < 3 {
			w("\tLSRW\t$4, R5, R5")
			w("\tLSRW\t$8, R6, R6")
		}
	}
	e.addv4s(20, 20)
	e.scvtf4s(20, 20)
	e.ldurH(22, 3, 0)
	e.ldurS(23, 4, 0)
	e.fcvtSH(22, 22)
	e.fmulS(22, 22, 23)
	e.fmlaLane(0, 20, 22, 0)
	w("\tADD\t$%d, R3, R3", iq4_xsBlockBytes)
	w("\tADD\t$%d, R4, R4", q8_KBlockBytes)
	w("\tSUBW\t$1, R1, R1")
	w("\tCBNZW\tR1, ixblk")
	w("ixreduce:")
	e.reduceStore(0, 2)
	w("\tRET")
	w("ixoob:")
	w("\tB\tovr_oob")
	return sb.String()
}
