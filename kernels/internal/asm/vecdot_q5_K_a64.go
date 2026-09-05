package asm

import "strings"

// q5_K x q8_K dot (ggml_vec_dot_q5_K_q8_K): the q4_K kernel
// (a64VecDotQ4_KKernel) with the fifth bit of every quant merged from
// qh, the arm64 llama.cpp structure: per 64-quant chunk j the qh halves
// (shifted down by 2j) supply bit 0 to the low nibbles and bit 1 to the
// high ones before the SDOTs. FastMath only. nrc == 2 is the 2x2 tile
// described at a64VecDotQ4_KKernel.
//
// Block layout (bytes): q5_K = d f16 (0) | dmin f16 (2) | scales[12] (4)
// | qh[32] (16) | qs[128] (48), 176 total.

const q5_KBlockBytes = 176

func a64VecDotQ5_KKernel(sym string, _ *ConstPool, wide bool) string {
	var sb strings.Builder
	e := newA64Q(&sb)
	w := e.w
	w("// %s: q5_K x q8_K dot, SDOT per sub-block with MLA-by-element scales, fifth bits from qh; 2x2 tile for nrc == 2.", sym)
	e.movi4s0(0)
	e.vecDotPrologue2(wide, 8, q5_KBlockBytes, q8_KBlockBytes, "q5koob", "q5kzero", "q5ktile")
	e.movi16(16, 15)
	w("q5kblk:")
	// qh halves (bits 2j / 2j+1 for sub-blocks 2j / 2j+1, shifted down per j)
	e.ldurQ(18, 3, 16)
	e.ldurQ(19, 3, 32)
	e.movi16(14, 1)
	e.movi16(15, 2)
	e.q4KScalesMins(3, 6, 2)
	e.ushll8h(3, 2)
	e.ushll4s(4, 3)   // sc0..3
	e.ushll2_4s(5, 3) // sc4..7
	// --- mins term: sum over 8 sub-blocks of (bsums[2k]+bsums[2k+1]) * m[k].
	w("\tADD\t$256, R4, R5")
	e.ldurQ(7, 5, 4)  // bsums[0..8)
	e.ldurQ(8, 5, 20) // bsums[8..16)
	e.addp8h(9, 7, 8) // pairwise: per sub-block activation sums
	e.ushll8h(6, 6)   // mins as i16
	e.smull4s(10, 9, 6)
	e.smlal2_4s(10, 9, 6)
	e.ldurS(11, 4, 0) // y.d
	e.ldurH(12, 3, 2) // x.dmin
	e.ldurH(13, 3, 0) // x.d
	e.fcvtSH(12, 12)
	e.fcvtSH(13, 13)
	e.fmulS(12, 12, 11)      // dmin = y.d * x.dmin
	e.fmulS(13, 13, 11)      // d = y.d * x.d
	e.addv4s(10, 10)         // reduce first: the nrc == 2 tile converts per-block scalars, so
	e.scvtf4s(10, 10)        // the single path must round the same way to stay bit-identical
	e.fmlsLane(0, 10, 12, 0) // sumf -= dmin * mins-term
	// --- the eight sub-blocks.
	e.movi4s0(1)
	for j := 0; j < 4; j++ {
		e.ldurQ(20, 3, 48+32*j)
		e.ldurQ(21, 3, 64+32*j)
		for k := 0; k < 4; k++ {
			e.ldurQ(22+k, 4, 4+64*j+16*k)
		}
		e.and16(26, 20, 16)
		e.and16(27, 21, 16)
		e.ushr16(28, 20, 4)
		e.ushr16(29, 21, 4)
		// fifth bits: (qh & 1) << 4 into the low nibbles, (qh & 2) << 3 into the high
		e.and16(17, 18, 14)
		e.shl16(17, 17, 4)
		e.orr16(26, 26, 17)
		e.and16(17, 19, 14)
		e.shl16(17, 17, 4)
		e.orr16(27, 27, 17)
		e.and16(17, 18, 15)
		e.shl16(17, 17, 3)
		e.orr16(28, 28, 17)
		e.and16(17, 19, 15)
		e.shl16(17, 17, 3)
		e.orr16(29, 29, 17)
		e.ushr16(18, 18, 2)
		e.ushr16(19, 19, 2)
		e.movi4s0(30)
		e.movi4s0(31)
		e.sdot(30, 26, 22)
		e.sdot(30, 27, 23)
		e.sdot(31, 28, 24)
		e.sdot(31, 29, 25)
		scReg, lane := 4, 2*(j%2)
		if j >= 2 {
			scReg = 5
		}
		e.mlaLane(1, 30, scReg, lane)
		e.mlaLane(1, 31, scReg, lane+1)
	}
	e.addv4s(1, 1)
	e.scvtf4s(1, 1)
	e.fmlaLane(0, 1, 13, 0) // sumf += d * (sumi1 + sumi2)
	w("\tADD\t$%d, R3, R3", q5_KBlockBytes)
	w("\tADD\t$%d, R4, R4", q8_KBlockBytes)
	w("\tSUBW\t$1, R1, R1")
	w("\tCBNZW\tR1, q5kblk")
	w("q5kzero:")
	w("\tCMPW\t$2, R6")
	w("\tBEQ\tq5ktilestore")
	e.reduceStore(0, 2)
	w("\tRET")

	// ---- nrc == 2 tile. R3/R5 = x0/x1, R4/R7 = y0/y1, R2/R8 = s/s+bs.
	// v0 f32 tile acc; v1..v4 i32 accs (x0y0, x1y0, x0y1, x1y1);
	// v5/v6 x0 scales (i32 lanes, sc0..3 / sc4..7), v7/v8 x1 scales;
	// v9/v10 mins x0/x1 (i16), v11/v12 q8sums y0/y1 (i16).
	w("q5ktile:")
	e.movi16(16, 15)
	w("q5ktileblk:")
	e.q4KScalesMins(3, 9, 5)
	e.q4KScalesMins(5, 10, 7)
	e.ushll8h(5, 5)
	e.ushll2_4s(6, 5)
	e.ushll4s(5, 5)
	e.ushll8h(7, 7)
	e.ushll2_4s(8, 7)
	e.ushll4s(7, 7)
	e.ushll8h(9, 9)
	e.ushll8h(10, 10)
	w("\tADD\t$256, R4, R9")
	e.ldurQ(13, 9, 4)
	e.ldurQ(14, 9, 20)
	e.addp8h(11, 13, 14)
	w("\tADD\t$256, R7, R9")
	e.ldurQ(13, 9, 4)
	e.ldurQ(14, 9, 20)
	e.addp8h(12, 13, 14)
	// bias tile [m0.q0, m1.q0, m0.q1, m1.q1] -> v13
	e.smull4s(13, 11, 9)
	e.smlal2_4s(13, 11, 9)
	e.smull4s(14, 11, 10)
	e.smlal2_4s(14, 11, 10)
	e.addv4s(13, 13)
	e.addv4s(14, 14)
	e.insS(13, 1, 14, 0)
	e.smull4s(14, 12, 9)
	e.smlal2_4s(14, 12, 9)
	e.addv4s(14, 14)
	e.insS(13, 2, 14, 0)
	e.smull4s(14, 12, 10)
	e.smlal2_4s(14, 12, 10)
	e.addv4s(14, 14)
	e.insS(13, 3, 14, 0)
	// factor tiles: v9 = [dx0,dx1,dx0,dx1] * [yd0,yd0,yd1,yd1]; v10 the dmin one.
	e.ldurS(11, 4, 0)
	e.ldurS(12, 7, 0)
	e.insS(11, 1, 12, 0)
	e.zip1_4s(11, 11, 11) // [yd0, yd0, yd1, yd1]
	e.ldurH(9, 3, 0)
	e.ldurH(12, 5, 0)
	e.fcvtSH(9, 9)
	e.fcvtSH(12, 12)
	e.insS(9, 1, 12, 0)
	e.dup2d(9, 9, 0) // [dx0, dx1, dx0, dx1]
	e.fmul4s(9, 9, 11)
	e.ldurH(10, 3, 2)
	e.ldurH(12, 5, 2)
	e.fcvtSH(10, 10)
	e.fcvtSH(12, 12)
	e.insS(10, 1, 12, 0)
	e.dup2d(10, 10, 0)
	e.fmul4s(10, 10, 11)
	e.scvtf4s(13, 13)
	e.fmls4s(0, 13, 10) // acc -= bias * dmin
	// --- the eight sub-blocks, four accumulators.
	for i := 1; i <= 4; i++ {
		e.movi4s0(i)
	}
	for j := 0; j < 4; j++ {
		e.ldurQ(17, 3, 48+32*j)
		e.ldurQ(18, 3, 64+32*j)
		e.ldurQ(21, 5, 48+32*j)
		e.ldurQ(22, 5, 64+32*j)
		e.and16(19, 17, 16) // x0 lo (sub-block 2j)
		e.and16(20, 18, 16)
		e.ushr16(17, 17, 4) // x0 hi (sub-block 2j+1)
		e.ushr16(18, 18, 4)
		e.and16(23, 21, 16) // x1 lo
		e.and16(24, 22, 16)
		e.ushr16(21, 21, 4) // x1 hi
		e.ushr16(22, 22, 4)
		// fifth bits from qh (reloaded per use: v13/v14 are the only free
		// registers here): bit 2j -> low nibbles, bit 2j+1 -> high
		for _, f := range []struct{ dst, xr, off, bit, sh int }{
			{19, 3, 16, 1, 4}, {20, 3, 32, 1, 4}, {17, 3, 16, 2, 3}, {18, 3, 32, 2, 3},
			{23, 5, 16, 1, 4}, {24, 5, 32, 1, 4}, {21, 5, 16, 2, 3}, {22, 5, 32, 2, 3},
		} {
			e.ldurQ(14, f.xr, f.off)
			if j > 0 {
				e.ushr16(14, 14, 2*j)
			}
			e.movi16(13, f.bit)
			e.and16(14, 14, 13)
			e.shl16(14, 14, f.sh)
			e.orr16(f.dst, f.dst, 14)
		}
		for k := 0; k < 4; k++ {
			e.ldurQ(25+k, 4, 4+64*j+16*k) // y0: 25,26 (2j), 27,28 (2j+1)
		}
		e.ldurQ(29, 7, 4+64*j) // y1: 29,30 (2j), 31,15 (2j+1)
		e.ldurQ(30, 7, 4+64*j+16)
		e.ldurQ(31, 7, 4+64*j+32)
		e.ldurQ(15, 7, 4+64*j+48)
		sub := func(k, xa0, xb0, xa1, xb1, ya0, yb0, ya1, yb1 int) {
			s0, s1 := 5, 7 // x0, x1 scale registers for sub-block k
			if k >= 4 {
				s0, s1 = 6, 8
			}
			lane := k % 4
			combos := [4][5]int{
				{1, xa0, xb0, ya0, yb0}, // x0.y0
				{2, xa1, xb1, ya0, yb0}, // x1.y0
				{3, xa0, xb0, ya1, yb1}, // x0.y1
				{4, xa1, xb1, ya1, yb1}, // x1.y1
			}
			for i, c := range combos {
				e.movi4s0(13)
				e.sdot(13, c[1], c[3])
				e.sdot(13, c[2], c[4])
				sc := s0
				if i%2 == 1 {
					sc = s1
				}
				e.mlaLane(c[0], 13, sc, lane)
			}
		}
		sub(2*j, 19, 20, 23, 24, 25, 26, 29, 30)
		sub(2*j+1, 17, 18, 21, 22, 27, 28, 31, 15)
	}
	for i := 1; i <= 4; i++ {
		e.addv4s(i, i)
	}
	e.insS(1, 1, 2, 0)
	e.insS(1, 2, 3, 0)
	e.insS(1, 3, 4, 0)
	e.scvtf4s(1, 1)
	e.fmla4s(0, 1, 9)
	w("\tADD\t$%d, R3, R3", q5_KBlockBytes)
	w("\tADD\t$%d, R5, R5", q5_KBlockBytes)
	w("\tADD\t$%d, R4, R4", q8_KBlockBytes)
	w("\tADD\t$%d, R7, R7", q8_KBlockBytes)
	w("\tSUBW\t$1, R1, R1")
	w("\tCBNZW\tR1, q5ktileblk")
	w("q5ktilestore:")
	e.storeTileRet(0)
	w("q5koob:")
	w("\tB\tovr_oob")
	return sb.String()
}
