package asm

import "strings"

// q4_K x q8_K dot (ggml_vec_dot_q4_K_q8_K), the arm64 llama.cpp
// structure: per 256-quant super-block the eight 6-bit sub-block
// scales and mins are unpacked from the 12 packed bytes, the mins
// term comes from the activation's block sums, and each 32-quant
// sub-block is one SDOT pair scaled by MLA-by-element into an i32
// accumulator that converts once per super-block. FastMath only.
//
// nrc == 2 (the wasm build's type_traits say nrows = 2 for q4_K and
// q6_K, like arm64 i8mm) is a 2x2 tile: weight rows x0 = vx and
// x1 = vx + bx against activation columns y0 = vy and y1 = vy + by,
// results s[0] = x0.y0, s[1] = x1.y0, s[bs] = x0.y1, s[bs+1] = x1.y1
// (bs in floats). The tile shares every weight unpack across the two
// columns and every activation load across the two rows, with four
// SDOT accumulators (no i8mm needed).
//
// Block layouts (bytes): q4_K = d f16 (0) | dmin f16 (2) | scales[12]
// (4) | qs[128] (16), 144 total; q8_K = d f32 (0) | qs[256] (4) |
// bsums[16] i16 (260), 292 total. Sub-block 2j is the low nibbles of
// qs[32j..32j+32), sub-block 2j+1 their high nibbles.

const (
	q4_KBlockBytes = 144
	q6_KBlockBytes = 210
	q8_KBlockBytes = 292
)

// vecDotPrologue2 loads the vec_dot frame for a kernel that handles
// nrc 1 and 2: R1 = nb (n >> shift), R2 = s, R3 = x, R4 = y (all host
// pointers after the range checks), and for nrc == 2 also R5 = x1,
// R7 = y1, R8 = s + bs (host), branching to tileLabel. nb == 0 jumps
// to zeroLabel (for nrc == 2 the four results are stored there too:
// the label must store from a zero accumulator through R2/R8). R6
// holds nrc throughout.
func (e *a64Q) vecDotPrologue2(wide bool, shift, xBlock, yBlock int, oob, zeroLabel, tileLabel string) {
	args, _ := vecDotArgs(wide)
	movPtr := "MOVWU"
	if wide {
		movPtr = "MOVD"
	}
	w := e.w
	w("\tMOVW\tl0+%d(FP), R1", args["l0"])
	w("\tLSRW\t$%d, R1, R1", shift)
	w("\tMOVW\tl7+%d(FP), R6", args["l7"])
	w("\t%s\tl1+%d(FP), R2", movPtr, args["l1"])
	w("\t%s\tl3+%d(FP), R3", movPtr, args["l3"])
	w("\t%s\tl5+%d(FP), R4", movPtr, args["l5"])
	w("\tCMPW\t$2, R6")
	w("\tBEQ\t%s_tilepro", tileLabel)
	// nrc == 1
	w("\tADD\t$4, R2, R27")
	w("\tCMP\tR27, R21")
	w("\tBLO\t%s", oob)
	w("\tADD\tR20, R2, R2")
	w("\tCBZW\tR1, %s", zeroLabel)
	w("\tMOVD\t$%d, R26", xBlock)
	w("\tMUL\tR1, R26, R26")
	w("\tADD\tR3, R26, R27")
	w("\tCMP\tR27, R21")
	w("\tBLO\t%s", oob)
	w("\tMOVD\t$%d, R26", yBlock)
	w("\tMUL\tR1, R26, R26")
	w("\tADD\tR4, R26, R27")
	w("\tCMP\tR27, R21")
	w("\tBLO\t%s", oob)
	w("\tADD\tR20, R3, R3")
	w("\tADD\tR20, R4, R4")
	w("\tB\t%s_body", tileLabel)
	// nrc == 2: s + 4*bs + 8, x + bx + nb*xBlock, y + by + nb*yBlock.
	w("%s_tilepro:", tileLabel)
	w("\t%s\tl2+%d(FP), R8", movPtr, args["l2"])
	w("\tLSL\t$2, R8, R8")
	w("\tADD\tR2, R8, R8")
	w("\tADD\t$8, R8, R27")
	w("\tCMP\tR27, R21")
	w("\tBLO\t%s", oob)
	w("\t%s\tl4+%d(FP), R5", movPtr, args["l4"])
	w("\tADD\tR3, R5, R5")
	w("\t%s\tl6+%d(FP), R7", movPtr, args["l6"])
	w("\tADD\tR4, R7, R7")
	w("\tMOVD\t$%d, R26", xBlock)
	w("\tMUL\tR1, R26, R26")
	w("\tADD\tR5, R26, R27")
	w("\tCMP\tR27, R21")
	w("\tBLO\t%s", oob)
	w("\tMOVD\t$%d, R26", yBlock)
	w("\tMUL\tR1, R26, R26")
	w("\tADD\tR7, R26, R27")
	w("\tCMP\tR27, R21")
	w("\tBLO\t%s", oob)
	w("\tADD\tR20, R2, R2")
	w("\tADD\tR20, R8, R8")
	w("\tADD\tR20, R3, R3")
	w("\tADD\tR20, R4, R4")
	w("\tADD\tR20, R5, R5")
	w("\tADD\tR20, R7, R7")
	w("\tCBZW\tR1, %s", zeroLabel)
	w("\tB\t%s", tileLabel)
	w("%s_body:", tileLabel)
}

// storeTile writes the tile accumulator acc (lanes x0y0, x1y0, x0y1,
// x1y1) to s (R2) and s + bs (R8); storeOne writes lane sum of acc to
// s (R2). Both end with RET.
func (e *a64Q) storeTileRet(acc int) {
	e.word(0xFC000000|uint32(2)<<5|uint32(acc), "stur d"+itoa(acc)+", [x2, #0]")
	e.word(0x5E180400|uint32(acc)<<5|uint32(acc), "mov d"+itoa(acc)+", v"+itoa(acc)+".d[1]")
	e.word(0xFC000000|uint32(8)<<5|uint32(acc), "stur d"+itoa(acc)+", [x8, #0]")
	e.w("\tRET")
}

func itoa(i int) string {
	if i < 10 {
		return string(rune('0' + i))
	}
	return string(rune('0'+i/10)) + string(rune('0'+i%10))
}

// q4KScalesMins unpacks a q4_K block's 12 scale bytes at (R<xr>) into
// the 8 mins (v<minsReg>.8b) and 8 scales (v<scReg>.8b), the
// get_scale_min_k4 layout, through R9..R13 (R7 is the tile's y1).
func (e *a64Q) q4KScalesMins(xr, minsReg, scReg int) {
	w := e.w
	w("\tMOVWU\t4(R%d), R9", xr)
	w("\tMOVWU\t8(R%d), R10", xr)
	w("\tMOVWU\t12(R%d), R11", xr)
	// mins: lane0 = utmp1 & 0x3f3f3f3f, lane1 = ((utmp2>>4) & 0x0f0f0f0f) | (((utmp1>>6) & 0x03030303) << 4)
	w("\tANDW\t$0x3f3f3f3f, R10, R12")
	w("\tLSRW\t$4, R11, R13")
	w("\tANDW\t$0x0f0f0f0f, R13, R13")
	w("\tLSRW\t$6, R10, R10")
	w("\tANDW\t$0x03030303, R10, R10")
	w("\tORRW\tR10<<4, R13, R13")
	w("\tORR\tR13<<32, R12, R12")
	e.fmovDX(minsReg, 12)
	// scales: lane0 = utmp0 & 0x3f3f3f3f, lane1 = (utmp2 & 0x0f0f0f0f) | (((utmp0>>6) & 0x03030303) << 4)
	w("\tANDW\t$0x3f3f3f3f, R9, R12")
	w("\tANDW\t$0x0f0f0f0f, R11, R13")
	w("\tLSRW\t$6, R9, R10")
	w("\tANDW\t$0x03030303, R10, R10")
	w("\tORRW\tR10<<4, R13, R13")
	w("\tORR\tR13<<32, R12, R12")
	e.fmovDX(scReg, 12)
}

// a64VecDotQ4_KKernel emits the kernel under sym. nrc == 1: R1 nb, R2
// s, R3 x, R4 y, R5 y+256 (bsums); v0 the f32 accumulator, v1 the
// per-block i32 accumulator, v16 = 0x0f. nrc == 2: see the tile
// section.
func a64VecDotQ4_KKernel(sym string, _ *ConstPool, wide bool) string {
	var sb strings.Builder
	e := newA64Q(&sb)
	w := e.w
	w("// %s: q4_K x q8_K dot, SDOT per sub-block with MLA-by-element scales; 2x2 tile for nrc == 2.", sym)
	e.movi4s0(0)
	e.vecDotPrologue2(wide, 8, q4_KBlockBytes, q8_KBlockBytes, "q4koob", "q4kzero", "q4ktile")
	e.movi16(16, 15)
	w("q4kblk:")
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
		e.ldurQ(20, 3, 16+32*j)
		e.ldurQ(21, 3, 32+32*j)
		for k := 0; k < 4; k++ {
			e.ldurQ(22+k, 4, 4+64*j+16*k)
		}
		e.and16(26, 20, 16)
		e.and16(27, 21, 16)
		e.ushr16(28, 20, 4)
		e.ushr16(29, 21, 4)
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
	w("\tADD\t$%d, R3, R3", q4_KBlockBytes)
	w("\tADD\t$%d, R4, R4", q8_KBlockBytes)
	w("\tSUBW\t$1, R1, R1")
	w("\tCBNZW\tR1, q4kblk")
	w("q4kzero:")
	w("\tCMPW\t$2, R6")
	w("\tBEQ\tq4ktilestore")
	e.reduceStore(0, 2)
	w("\tRET")

	// ---- nrc == 2 tile. R3/R5 = x0/x1, R4/R7 = y0/y1, R2/R8 = s/s+bs.
	// v0 f32 tile acc; v1..v4 i32 accs (x0y0, x1y0, x0y1, x1y1);
	// v5/v6 x0 scales (i32 lanes, sc0..3 / sc4..7), v7/v8 x1 scales;
	// v9/v10 mins x0/x1 (i16), v11/v12 q8sums y0/y1 (i16).
	w("q4ktile:")
	e.movi16(16, 15)
	w("q4ktileblk:")
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
		e.ldurQ(17, 3, 16+32*j)
		e.ldurQ(18, 3, 32+32*j)
		e.ldurQ(21, 5, 16+32*j)
		e.ldurQ(22, 5, 32+32*j)
		e.and16(19, 17, 16) // x0 lo (sub-block 2j)
		e.and16(20, 18, 16)
		e.ushr16(17, 17, 4) // x0 hi (sub-block 2j+1)
		e.ushr16(18, 18, 4)
		e.and16(23, 21, 16) // x1 lo
		e.and16(24, 22, 16)
		e.ushr16(21, 21, 4) // x1 hi
		e.ushr16(22, 22, 4)
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
	w("\tADD\t$%d, R3, R3", q4_KBlockBytes)
	w("\tADD\t$%d, R5, R5", q4_KBlockBytes)
	w("\tADD\t$%d, R4, R4", q8_KBlockBytes)
	w("\tADD\t$%d, R7, R7", q8_KBlockBytes)
	w("\tSUBW\t$1, R1, R1")
	w("\tCBNZW\tR1, q4ktileblk")
	w("q4ktilestore:")
	e.storeTileRet(0)
	w("q4koob:")
	w("\tB\tovr_oob")
	return sb.String()
}
