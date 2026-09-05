package asm

import "strings"

// q3_K x q8_K dot (ggml_vec_dot_q3_K_q8_K). The 16 six-bit sub-block
// scales are unpacked from 12 bytes and centred (-32); each quant is
// rebuilt unsigned as its 2-bit field plus the hmask bit as the third
// bit (0..7), so the SDOTs run on unsigned bytes and the -4 offset is
// applied once per super-block through the activation block sums:
// sumi = sum_j sc_j * dot(u_j, y_j) - 4 * sum_j sc_j * bsums_j. Per
// 32-quant pair of sub-blocks two SDOTs, scaled by MLA-by-element into
// an i32 accumulator that converts once per super-block. FastMath only.
// nrc is 1 (the type's nrows).
//
// Block layout (bytes): q3_K = hmask[32] (0) | qs[64] (32) | scales[12]
// (96) | d f16 (108), 110 total; q8_K as in q4_K.

const q3_KBlockBytes = 110

// a64VecDotQ3_KKernel emits the kernel under sym. R1 nb, R2 s, R3 x,
// R4 y, R5 y+256 (bsums), R13/R14/R15/R19/R22 scale decode scratch; v0
// the f32 accumulator, v1 the per-block i32 accumulator, v8..v11 the 16
// scales as i32 lanes, v29 = 0x03, v30 = 0x01, v31 = 32.
func a64VecDotQ3_KKernel(sym string, _ *ConstPool, wide bool) string {
	var sb strings.Builder
	e := newA64Q(&sb)
	w := e.w
	w("// %s: q3_K x q8_K dot, SDOT per 16-quant sub-block on unsigned rebuilt quants, -4 through the block sums.", sym)
	e.movi4s0(0)
	e.vecDotPrologue(wide, 8, q3_KBlockBytes, q8_KBlockBytes, "q3koob", "q3kzero")
	e.movi16(29, 3)
	e.movi16(30, 1)
	e.movi16(31, 32)
	w("q3kblk:")
	// scales: aux0/1/2 -> utmp0..3 (kmask1 = 0x03030303, kmask2 = 0x0f0f0f0f)
	w("\tMOVWU\t96(R3), R13")  // aux0
	w("\tMOVWU\t100(R3), R14") // aux1
	w("\tMOVWU\t104(R3), R15") // aux2
	// utmp0 = (aux0 & kmask2) | ((aux2 & kmask1) << 4)
	w("\tANDW\t$0x0f0f0f0f, R13, R19")
	w("\tANDW\t$0x03030303, R15, R22")
	w("\tORRW\tR22<<4, R19, R19")
	// utmp1 = (aux1 & kmask2) | (((aux2 >> 2) & kmask1) << 4) -> high word of R19
	w("\tANDW\t$0x0f0f0f0f, R14, R22")
	w("\tLSRW\t$2, R15, R26")
	w("\tANDW\t$0x03030303, R26, R26")
	w("\tORRW\tR26<<4, R22, R22")
	w("\tORR\tR22<<32, R19, R19")
	e.fmovDX(2, 19)
	// utmp2 = ((aux0 >> 4) & kmask2) | (((aux2 >> 4) & kmask1) << 4)
	w("\tLSRW\t$4, R13, R19")
	w("\tANDW\t$0x0f0f0f0f, R19, R19")
	w("\tLSRW\t$4, R15, R22")
	w("\tANDW\t$0x03030303, R22, R22")
	w("\tORRW\tR22<<4, R19, R19")
	// utmp3 = ((aux1 >> 4) & kmask2) | (((aux2 >> 6) & kmask1) << 4)
	w("\tLSRW\t$4, R14, R22")
	w("\tANDW\t$0x0f0f0f0f, R22, R22")
	w("\tLSRW\t$6, R15, R26")
	w("\tANDW\t$0x03030303, R26, R26")
	w("\tORRW\tR26<<4, R22, R22")
	w("\tORR\tR22<<32, R19, R19")
	e.fmovDX(3, 19)
	// centre (-32), widen: v2/v3 i16 scales 0..7 / 8..15, v8..v11 i32 lanes
	e.sub16(2, 2, 31)
	e.sub16(3, 3, 31)
	e.sshll8h(2, 2)
	e.sshll8h(3, 3)
	e.sshll4s(8, 2)
	e.sshll2_4s(9, 2)
	e.sshll4s(10, 3)
	e.sshll2_4s(11, 3)
	// bias: 4 * sum(sc * bsums) -> v16
	w("\tADD\t$256, R4, R5")
	e.ldurQ(14, 5, 4)
	e.ldurQ(15, 5, 20)
	e.smull4s(16, 14, 2)
	e.smlal2_4s(16, 14, 2)
	e.smlal4s(16, 15, 3)
	e.smlal2_4s(16, 15, 3)
	e.shl4s(16, 16, 2)
	// quants: hmask halves v18/v19; halves of 128, four 2-bit fields each
	e.ldurQ(18, 3, 0)
	e.ldurQ(19, 3, 16)
	e.movi4s0(1)
	for j := 0; j < 2; j++ {
		e.ldurQ(20, 3, 32+32*j)
		e.ldurQ(21, 3, 48+32*j)
		for s := 0; s < 4; s++ {
			e.ldurQ(22, 4, 4+128*j+32*s)
			e.ldurQ(23, 4, 4+128*j+32*s+16)
			if s == 0 {
				e.and16(26, 20, 29)
				e.and16(27, 21, 29)
			} else {
				e.ushr16(26, 20, 2*s)
				e.ushr16(27, 21, 2*s)
				e.and16(26, 26, 29)
				e.and16(27, 27, 29)
			}
			// third bit: hmask bit 4j+s
			k := 4*j + s
			for _, h := range []struct{ src, dst int }{{18, 26}, {19, 27}} {
				if k == 0 {
					e.and16(24, h.src, 30)
				} else {
					e.ushr16(24, h.src, k)
					e.and16(24, 24, 30)
				}
				e.shl16(24, 24, 2)
				e.orr16(h.dst, h.dst, 24)
			}
			e.movi4s0(12)
			e.movi4s0(13)
			e.sdot(12, 26, 22)
			e.sdot(13, 27, 23)
			is := 8*j + 2*s
			e.mlaLane(1, 12, 8+is/4, is%4)
			e.mlaLane(1, 13, 8+(is+1)/4, (is+1)%4)
		}
	}
	e.sub4s(1, 1, 16)
	e.scvtf4s(1, 1)
	// d = y.d * f16(x.d)
	e.ldurS(17, 4, 0)
	e.ldurH(25, 3, 108)
	e.fcvtSH(25, 25)
	e.fmulS(25, 25, 17)
	e.fmlaLane(0, 1, 25, 0)
	w("\tADD\t$%d, R3, R3", q3_KBlockBytes)
	w("\tADD\t$%d, R4, R4", q8_KBlockBytes)
	w("\tSUBW\t$1, R1, R1")
	w("\tCBNZW\tR1, q3kblk")
	w("q3kzero:")
	e.reduceStore(0, 2)
	w("\tRET")
	w("q3koob:")
	w("\tB\tovr_oob")
	return sb.String()
}
