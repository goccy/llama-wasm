package asm

import "strings"

// q6_K x q8_K dot (ggml_vec_dot_q6_K_q8_K), the arm64 llama.cpp
// structure: the 6-bit quants are rebuilt unsigned (low nibble from
// ql, two high bits from qh), dotted against the activation by SDOT
// per 16-quant group and scaled by MLA-by-element with the block's 16
// i8 scales; the -32 offset is applied once per super-block through
// the activation block sums (isum - 32 * sum(bsums * scales)).
// FastMath only. nrc == 2 is the 2x2 tile described at
// a64VecDotQ4_KKernel.
//
// Block layouts (bytes): q6_K = ql[128] (0) | qh[64] (128) |
// scales[16] i8 (192) | d f16 (208), 210 total; q8_K as in q4_K.

// a64VecDotQ6_KKernel emits the kernel under sym. nrc == 1: R1 nb,
// R2 s, R3 x, R4 y, R5 y+256 (bsums); v0 the f32 accumulator, v1 the
// per-block i32 accumulator, v16 = 0x0f, v17 = 0x03; v4..v7 the 16
// scales as i32 lanes. nrc == 2: see the tile section.
func a64VecDotQ6_KKernel(sym string, _ *ConstPool, wide bool) string {
	var sb strings.Builder
	e := newA64Q(&sb)
	w := e.w
	w("// %s: q6_K x q8_K dot, SDOT per 16-quant group with MLA-by-element scales; 2x2 tile for nrc == 2.", sym)
	e.movi4s0(0)
	e.vecDotPrologue2(wide, 8, q6_KBlockBytes, q8_KBlockBytes, "q6koob", "q6kzero", "q6ktile")
	e.movi16(16, 15)
	e.movi16(17, 3)
	w("q6kblk:")
	// --- scales: 16 x i8 -> i16 (v2, v3) -> i32 (v4..v7).
	e.ldurQ(2, 3, 192)
	e.sshll2_8h(3, 2)
	e.sshll8h(2, 2)
	e.sshll4s(4, 2)
	e.sshll2_4s(5, 2)
	e.sshll4s(6, 3)
	e.sshll2_4s(7, 3)
	e.movi4s0(1)
	for j := 0; j < 2; j++ {
		e.ldurQ(18, 3, 128+32*j) // qh[0..16)
		e.ldurQ(19, 3, 144+32*j) // qh[16..32)
		for k := 0; k < 4; k++ {
			e.ldurQ(20+k, 3, 64*j+16*k) // ql
		}
		// first 64 quants: low nibbles, qh bits 0-1 (groups 0,1) and 2-3 (groups 2,3).
		for k := 0; k < 4; k++ {
			e.ldurQ(24+k, 4, 4+128*j+16*k)
		}
		e.and16(28, 18, 17)
		e.and16(29, 19, 17)
		e.ushr16(30, 18, 2)
		e.ushr16(31, 19, 2)
		e.and16(30, 30, 17)
		e.and16(31, 31, 17)
		for k := 0; k < 4; k++ {
			e.shl16(28+k, 28+k, 4)
		}
		for k := 0; k < 4; k++ {
			e.and16(12+k, 20+k, 16)
			e.orr16(12+k, 12+k, 28+k)
		}
		for k := 0; k < 4; k++ {
			e.movi4s0(8 + k)
			e.sdot(8+k, 12+k, 24+k)
		}
		for k := 0; k < 4; k++ {
			s := 8*j + k
			e.mlaLane(1, 8+k, 4+s/4, s%4)
		}
		// second 64 quants: high nibbles, qh bits 4-5 and 6-7.
		for k := 0; k < 4; k++ {
			e.ldurQ(24+k, 4, 4+128*j+64+16*k)
		}
		e.ushr16(28, 18, 4)
		e.ushr16(29, 19, 4)
		e.ushr16(30, 18, 6)
		e.ushr16(31, 19, 6)
		e.and16(28, 28, 17)
		e.and16(29, 29, 17)
		for k := 0; k < 4; k++ {
			e.shl16(28+k, 28+k, 4)
		}
		for k := 0; k < 4; k++ {
			e.ushr16(12+k, 20+k, 4)
			e.orr16(12+k, 12+k, 28+k)
		}
		for k := 0; k < 4; k++ {
			e.movi4s0(8 + k)
			e.sdot(8+k, 12+k, 24+k)
		}
		for k := 0; k < 4; k++ {
			s := 8*j + 4 + k
			e.mlaLane(1, 8+k, 4+s/4, s%4)
		}
	}
	// --- mins term: sum(bsums[i] * scales[i]) (v2/v3 still hold the
	// i16 scales; the loop's dot accumulators v8..v11 are free again).
	w("\tADD\t$256, R4, R5")
	e.ldurQ(8, 5, 4)
	e.ldurQ(9, 5, 20)
	e.smull4s(10, 8, 2)
	e.smlal2_4s(10, 8, 2)
	e.smlal4s(10, 9, 3)
	e.smlal2_4s(10, 9, 3)
	// d = f16(x.d) * y.d; sumf -= d * 32 * mins-term, sumf += d * isum, each
	// reduced to a per-block scalar before converting: the nrc == 2 tile
	// folds this way, so the single path rounds identically.
	e.ldurS(11, 4, 0)
	e.ldurH(13, 3, 208)
	e.fcvtSH(13, 13)
	e.fmulS(13, 13, 11)
	e.shl4s(10, 10, 5)
	e.addv4s(10, 10)
	e.scvtf4s(10, 10)
	e.fmlsLane(0, 10, 13, 0)
	e.addv4s(1, 1)
	e.scvtf4s(1, 1)
	e.fmlaLane(0, 1, 13, 0)
	w("\tADD\t$%d, R3, R3", q6_KBlockBytes)
	w("\tADD\t$%d, R4, R4", q8_KBlockBytes)
	w("\tSUBW\t$1, R1, R1")
	w("\tCBNZW\tR1, q6kblk")
	w("q6kzero:")
	w("\tCMPW\t$2, R6")
	w("\tBEQ\tq6ktilestore")
	e.reduceStore(0, 2)
	w("\tRET")

	// ---- nrc == 2 tile. R3/R5 = x0/x1, R4/R7 = y0/y1, R2/R8 = s/s+bs.
	// v0 f32 tile acc; v1..v4 i32 accs (x0y0, x1y0, x0y1, x1y1);
	// v5..v8 x0 scales (i32 lanes, 16), v9..v12 x1 scales; v13 = 0x0f,
	// v14 = 0x30; v15 partial; v16..v19 x0 groups, v20..v23 x1 groups;
	// v24/v25 x0 qh, v26/v27 x1 qh; v28/v29 y0/y1 group; v30 the d
	// tile; v31 scratch.
	w("q6ktile:")
	e.movi16(13, 15)
	e.movi16(14, 0x30)
	w("q6ktileblk:")
	// scales as i16: x0 -> v5 (0..7), v6 (8..15); x1 -> v9, v10.
	e.ldurQ(5, 3, 192)
	e.sshll2_8h(6, 5)
	e.sshll8h(5, 5)
	e.ldurQ(9, 5, 192)
	e.sshll2_8h(10, 9)
	e.sshll8h(9, 9)
	// bsums: y0 -> v28/v29, y1 -> v16/v17.
	w("\tADD\t$256, R4, R9")
	e.ldurQ(28, 9, 4)
	e.ldurQ(29, 9, 20)
	w("\tADD\t$256, R7, R9")
	e.ldurQ(16, 9, 4)
	e.ldurQ(17, 9, 20)
	// bias tile -> v18: [x0.y0, x1.y0, x0.y1, x1.y1] of sum(bsums * scales).
	bias := func(ylo, yhi, slo, shi int) {
		e.smull4s(15, ylo, slo)
		e.smlal2_4s(15, ylo, slo)
		e.smlal4s(15, yhi, shi)
		e.smlal2_4s(15, yhi, shi)
		e.addv4s(15, 15)
	}
	bias(28, 29, 5, 6)
	e.insS(18, 0, 15, 0)
	bias(28, 29, 9, 10)
	e.insS(18, 1, 15, 0)
	bias(16, 17, 5, 6)
	e.insS(18, 2, 15, 0)
	bias(16, 17, 9, 10)
	e.insS(18, 3, 15, 0)
	// scales to i32: x0 v5..v8, x1 v9..v12.
	e.sshll4s(7, 6)
	e.sshll2_4s(8, 6)
	e.sshll2_4s(6, 5)
	e.sshll4s(5, 5)
	e.sshll4s(11, 10)
	e.sshll2_4s(12, 10)
	e.sshll2_4s(10, 9)
	e.sshll4s(9, 9)
	// d tile v30 = [dx0, dx1, dx0, dx1] * [yd0, yd0, yd1, yd1].
	e.ldurS(31, 4, 0)
	e.ldurS(15, 7, 0)
	e.insS(31, 1, 15, 0)
	e.zip1_4s(31, 31, 31)
	e.ldurH(30, 3, 208)
	e.ldurH(15, 5, 208)
	e.fcvtSH(30, 30)
	e.fcvtSH(15, 15)
	e.insS(30, 1, 15, 0)
	e.dup2d(30, 30, 0)
	e.fmul4s(30, 30, 31)
	// acc -= 32 * bias * d
	e.shl4s(18, 18, 5)
	e.scvtf4s(18, 18)
	e.fmls4s(0, 18, 30)
	for i := 1; i <= 4; i++ {
		e.movi4s0(i)
	}
	for j := 0; j < 2; j++ {
		e.ldurQ(24, 3, 128+32*j)
		e.ldurQ(25, 3, 144+32*j)
		e.ldurQ(26, 5, 128+32*j)
		e.ldurQ(27, 5, 144+32*j)
		for phase := 0; phase < 2; phase++ {
			// unpack the four 16-quant groups of this phase for both rows.
			for r := 0; r < 2; r++ {
				xr, base, qh0, qh1 := 3, 16, 24, 25
				if r == 1 {
					xr, base, qh0, qh1 = 5, 20, 26, 27
				}
				for k := 0; k < 4; k++ {
					e.ldurQ(base+k, xr, 64*j+16*k)
				}
				for k := 0; k < 4; k++ {
					qh := qh0
					if k%2 == 1 {
						qh = qh1
					}
					if phase == 0 {
						if k < 2 {
							e.shl16(31, qh, 4)
						} else {
							e.shl16(31, qh, 2)
						}
						e.and16(31, 31, 14)
						e.and16(base+k, base+k, 13)
					} else {
						if k < 2 {
							e.and16(31, qh, 14)
						} else {
							e.ushr16(31, qh, 2)
							e.and16(31, 31, 14)
						}
						e.ushr16(base+k, base+k, 4)
					}
					e.orr16(base+k, base+k, 31)
				}
			}
			for k := 0; k < 4; k++ {
				yoff := 4 + 128*j + 64*phase + 16*k
				e.ldurQ(28, 4, yoff)
				e.ldurQ(29, 7, yoff)
				g := 8*j + 4*phase + k
				combos := [4][3]int{{1, 16 + k, 28}, {2, 20 + k, 28}, {3, 16 + k, 29}, {4, 20 + k, 29}}
				for i, c := range combos {
					e.movi4s0(15)
					e.sdot(15, c[1], c[2])
					sc := 5 + g/4
					if i%2 == 1 {
						sc = 9 + g/4
					}
					e.mlaLane(c[0], 15, sc, g%4)
				}
			}
		}
	}
	for i := 1; i <= 4; i++ {
		e.addv4s(i, i)
	}
	e.insS(1, 1, 2, 0)
	e.insS(1, 2, 3, 0)
	e.insS(1, 3, 4, 0)
	e.scvtf4s(1, 1)
	e.fmla4s(0, 1, 30)
	w("\tADD\t$%d, R3, R3", q6_KBlockBytes)
	w("\tADD\t$%d, R5, R5", q6_KBlockBytes)
	w("\tADD\t$%d, R4, R4", q8_KBlockBytes)
	w("\tADD\t$%d, R7, R7", q8_KBlockBytes)
	w("\tSUBW\t$1, R1, R1")
	w("\tCBNZW\tR1, q6ktileblk")
	w("q6ktilestore:")
	e.storeTileRet(0)
	w("q6koob:")
	w("\tB\tovr_oob")
	return sb.String()
}
