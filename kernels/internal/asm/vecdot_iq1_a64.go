package asm

import (
	"encoding/binary"
	"strings"
)

// iq1_s and iq1_m x q8_K dots (ggml_vec_dot_iq1_s_q8_K, ggml_vec_dot_iq1_m_q8_K):
// 1-bit codebook formats. Every 8-quant group is one u64 of iq1s_grid (eight
// signed ternary bytes) looked up by an 11-bit index, plus a per-group or
// per-sub-block +-1 "delta" that shifts every quant by IQ1S_DELTA (0.125);
// the delta term is the activation sum of the group times the sign, so the
// kernels take it as an SDOT of the activations against +-1 bytes. Scales are
// 3-bit integers 2*s + 1 per sub-block (iq1_s, from qh) or per 16 quants
// (iq1_m, packed in the four scale words whose top nibbles form the block's
// f16 scale). The super-block's two i32 totals combine as sumi + 0.125 *
// sumi_delta and scale once by the block's f16 d times y.d. FastMath only.
//
// Block layouts (bytes): iq1_s = d f16 (0) | qs[32] (2) | qh u16[8] (34), 50
// total; iq1_m = qs[32] (0) | qh[16] (32) | scales u16[4] (48), 56 total.

const (
	iq1_sBlockBytes = 50
	iq1_mBlockBytes = 56
)

// iq1Consts: 0: iq1s_grid (2048 x u64); 16384: the +-1 delta masks for
// iq1_m: [0x08 x8 | 0x80 x8] tests the two flag bits of a qh byte over the
// two groups it covers.
func iq1Consts() []byte {
	c := make([]byte, 16384+16)
	for i, v := range iq1sGrid {
		binary.LittleEndian.PutUint64(c[8*i:], v)
	}
	for i := 0; i < 8; i++ {
		c[16384+i] = 0x08
		c[16384+8+i] = 0x80
	}
	return c
}

// a64VecDotIQ1SKernel emits the iq1_s dot under sym. Registers: R1 nb, R2
// s, R3 x, R4 y, R12 grid, R5-R9 scratch; v0 the f32 accumulator, v17 =
// 0.125, v20 sumi, v24 sumi_delta (i32), v21 the scale broadcast.
func a64VecDotIQ1SKernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	e := newA64Q(&sb)
	w := e.w
	cSym := pool.addBlob(iq1Consts())
	w("// %s: iq1_s x q8_K dot, u64 grid gathers, SDOT per sub-block, delta from bsums.", sym)
	e.movi4s0(0)
	e.vecDotPrologue(wide, 8, iq1_sBlockBytes, q8_KBlockBytes, "i1soob", "i1sreduce")
	w("\tMOVD\t$·%s(SB), R12", cSym)
	w("\tMOVW\t$0x3E000000, R5") // 0.125f
	e.fmovSW(17, 5)
	w("i1sblk:")
	e.movi4s0(20)
	e.movi4s0(24)
	for ib := 0; ib < 8; ib++ {
		w("\tMOVWU\t%d(R3), R5", 2+4*ib)  // four index bytes
		w("\tMOVHU\t%d(R3), R6", 34+2*ib) // qh: 3 high index bits per group | scale | delta sign
		for l := 0; l < 4; l++ {
			w("\tUBFX\t$%d, R5, $8, R7", 8*l)
			w("\tUBFX\t$%d, R6, $3, R8", 3*l)
			w("\tORR\tR8<<8, R7, R7")
			w("\tMOVD\t(R12)(R7<<3), R8")
			e.insDX(2+l/2, l%2, 8)
		}
		e.ldurQ(6, 4, 4+32*ib)
		e.ldurQ(7, 4, 4+32*ib+16)
		e.movi4s0(12)
		e.sdot(12, 2, 6)
		e.sdot(12, 3, 7)
		w("\tUBFX\t$12, R6, $3, R7")
		w("\tLSLW\t$1, R7, R7")
		w("\tADDW\t$1, R7, R7") // ls = 2*((qh >> 12) & 7) + 1
		e.dup4sW(21, 7)
		e.mla4s(20, 12, 21)
		// delta term: ls * (+-1) * (bsums[2ib] + bsums[2ib+1])
		w("\tMOVH\t%d(R4), R8", 260+4*ib)
		w("\tMOVH\t%d(R4), R9", 262+4*ib)
		w("\tADDW\tR9, R8, R8")
		w("\tMULW\tR7, R8, R8")
		w("\tTBZ\t$15, R6, i1spos%d", ib)
		w("\tNEGW\tR8, R8")
		w("i1spos%d:", ib)
		e.insSW(25, ib%4, 8) // lanes gather four sub-blocks' terms
		if ib%4 == 3 {
			e.add4s(24, 24, 25)
		}
	}
	e.addv4s(20, 20)
	e.addv4s(24, 24)
	e.scvtf4s(20, 20)
	e.scvtf4s(24, 24)
	e.fmlaLane(20, 24, 17, 0) // sumi + 0.125 * sumi_delta
	e.ldurH(22, 3, 0)
	e.ldurS(23, 4, 0)
	e.fcvtSH(22, 22)
	e.fmulS(22, 22, 23)
	e.fmlaLane(0, 20, 22, 0)
	w("\tADD\t$%d, R3, R3", iq1_sBlockBytes)
	w("\tADD\t$%d, R4, R4", q8_KBlockBytes)
	w("\tSUBW\t$1, R1, R1")
	w("\tCBNZW\tR1, i1sblk")
	w("i1sreduce:")
	e.reduceStore(0, 2)
	w("\tRET")
	w("i1soob:")
	w("\tB\tovr_oob")
	return sb.String()
}

// a64VecDotIQ1MKernel emits the iq1_m dot under sym. Registers as above
// plus R10/R11 for the scale words; v18 the delta flag masks, v23 = 0x01,
// v4/v5 the +-1 delta vectors.
func a64VecDotIQ1MKernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	e := newA64Q(&sb)
	w := e.w
	cSym := pool.addBlob(iq1Consts())
	w("// %s: iq1_m x q8_K dot, u64 grid gathers, per-16-quant scales, delta through +-1 SDOT.", sym)
	e.movi4s0(0)
	e.vecDotPrologue(wide, 8, iq1_mBlockBytes, q8_KBlockBytes, "i1moob", "i1mreduce")
	w("\tMOVD\t$·%s(SB), R12", cSym)
	w("\tADD\t$16384, R12, R13")
	e.ldurQ(18, 13, 0)
	e.movi16(23, 1)
	w("\tMOVW\t$0x3E000000, R5") // 0.125f
	e.fmovSW(17, 5)
	w("i1mblk:")
	e.movi4s0(20)
	e.movi4s0(24)
	for ib := 0; ib < 8; ib++ {
		w("\tMOVWU\t%d(R3), R5", 4*ib)         // four index bytes
		w("\tMOVHU\t%d(R3), R6", 32+2*ib)      // two qh bytes: 3 high bits + delta flag per group
		w("\tMOVHU\t%d(R3), R10", 48+2*(ib/2)) // scale word
		for l := 0; l < 4; l++ {
			w("\tUBFX\t$%d, R5, $8, R7", 8*l)
			w("\tUBFX\t$%d, R6, $3, R8", 4*l)
			w("\tORR\tR8<<8, R7, R7")
			w("\tMOVD\t(R12)(R7<<3), R8")
			e.insDX(2+l/2, l%2, 8)
		}
		// delta signs: byte qh[0] covers groups 0/1 (flags 0x08 / 0x80), qh[1] groups 2/3
		e.dup16W(4, 6)
		w("\tLSRW\t$8, R6, R7")
		e.dup16W(5, 7)
		e.cmtst16(4, 4, 18)
		e.cmtst16(5, 5, 18)
		e.orr16(4, 4, 23) // 0xff (-1) where the flag is set, +1 otherwise
		e.orr16(5, 5, 23)
		e.ldurQ(6, 4, 4+32*ib)
		e.ldurQ(7, 4, 4+32*ib+16)
		e.movi4s0(12)
		e.sdot(12, 2, 6) // sum1[0]
		e.movi4s0(13)
		e.sdot(13, 3, 7) // sum1[1]
		e.movi4s0(14)
		e.sdot(14, 4, 6) // sum2[0]
		e.movi4s0(15)
		e.sdot(15, 5, 7) // sum2[1]
		w("\tUBFX\t$%d, R10, $3, R7", 6*(ib%2))
		w("\tLSLW\t$1, R7, R7")
		w("\tADDW\t$1, R7, R7") // ls1
		e.dup4sW(21, 7)
		e.mla4s(20, 12, 21)
		e.mla4s(24, 14, 21)
		w("\tUBFX\t$%d, R10, $3, R7", 6*(ib%2)+3)
		w("\tLSLW\t$1, R7, R7")
		w("\tADDW\t$1, R7, R7") // ls2
		e.dup4sW(21, 7)
		e.mla4s(20, 13, 21)
		e.mla4s(24, 15, 21)
	}
	e.addv4s(20, 20)
	e.addv4s(24, 24)
	e.scvtf4s(20, 20)
	e.scvtf4s(24, 24)
	e.fmlaLane(20, 24, 17, 0) // sumi1 + 0.125 * sumi2
	// the block scale: top nibbles of the four scale words as one f16
	w("\tMOVHU\t48(R3), R7")
	w("\tLSRW\t$12, R7, R7")
	w("\tMOVHU\t50(R3), R8")
	w("\tLSRW\t$8, R8, R8")
	w("\tANDW\t$0xf0, R8, R8")
	w("\tORRW\tR8, R7, R7")
	w("\tMOVHU\t52(R3), R8")
	w("\tLSRW\t$4, R8, R8")
	w("\tANDW\t$0xf00, R8, R8")
	w("\tORRW\tR8, R7, R7")
	w("\tMOVHU\t54(R3), R8")
	w("\tANDW\t$0xf000, R8, R8")
	w("\tORRW\tR8, R7, R7")
	e.fmovSW(22, 7)
	e.fcvtSH(22, 22)
	e.ldurS(26, 4, 0)
	e.fmulS(22, 22, 26)
	e.fmlaLane(0, 20, 22, 0)
	w("\tADD\t$%d, R3, R3", iq1_mBlockBytes)
	w("\tADD\t$%d, R4, R4", q8_KBlockBytes)
	w("\tSUBW\t$1, R1, R1")
	w("\tCBNZW\tR1, i1mblk")
	w("i1mreduce:")
	e.reduceStore(0, 2)
	w("\tRET")
	w("i1moob:")
	w("\tB\tovr_oob")
	return sb.String()
}
