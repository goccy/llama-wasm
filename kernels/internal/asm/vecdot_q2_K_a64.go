package asm

import "strings"

// q2_K x q8_K dot (ggml_vec_dot_q2_K_q8_K), the arm64 llama.cpp
// structure: per 256-quant super-block the 16 sub-block scales and mins
// are the low and high nibbles of 16 bytes, the mins term is their dot
// with the activation block sums, and each 32-quant pair of sub-blocks
// is two SDOTs of the 2-bit quants (shifted out of 32 bytes four times)
// scaled by MLA-by-element into an i32 accumulator that converts once
// per super-block. FastMath only. nrc is 1 (the type's nrows).
//
// Block layout (bytes): q2_K = scales[16] (0) | qs[64] (16) | d f16 (80)
// | dmin f16 (82), 84 total; q8_K as in q4_K.

const q2_KBlockBytes = 84

// a64VecDotQ2_KKernel emits the kernel under sym. R1 nb, R2 s, R3 x,
// R4 y, R5 y+256 (bsums); v0 the f32 accumulator, v1 the per-block i32
// accumulator, v8..v11 the 16 scales as i32 lanes, v30 = 0x0f, v31 =
// 0x03.
func a64VecDotQ2_KKernel(sym string, _ *ConstPool, wide bool) string {
	var sb strings.Builder
	e := newA64Q(&sb)
	w := e.w
	w("// %s: q2_K x q8_K dot, SDOT per 16-quant sub-block with MLA-by-element scales.", sym)
	e.movi4s0(0)
	e.vecDotPrologue(wide, 8, q2_KBlockBytes, q8_KBlockBytes, "q2koob", "q2kzero")
	e.movi16(30, 15)
	e.movi16(31, 3)
	w("q2kblk:")
	// scales (low nibbles) as i32 lanes v8..v11, mins (high nibbles) as i16 v12/v13
	e.ldurQ(2, 3, 0)
	e.and16(4, 2, 30)
	e.ushr16(5, 2, 4)
	e.ushll8h(6, 4)
	e.ushll2_8h(7, 4)
	e.ushll4s(8, 6)
	e.ushll2_4s(9, 6)
	e.ushll4s(10, 7)
	e.ushll2_4s(11, 7)
	e.ushll8h(12, 5)
	e.ushll2_8h(13, 5)
	// mins term: sum over the 16 sub-blocks of mins * bsums
	w("\tADD\t$256, R4, R5")
	e.ldurQ(14, 5, 4)
	e.ldurQ(15, 5, 20)
	e.smull4s(16, 14, 12)
	e.smlal2_4s(16, 14, 12)
	e.smlal4s(16, 15, 13)
	e.smlal2_4s(16, 15, 13)
	// d = y.d * f16(x.d) (s19), dmin = y.d * f16(x.dmin) (s18)
	e.ldurS(17, 4, 0)
	e.ldurH(18, 3, 82)
	e.ldurH(19, 3, 80)
	e.fcvtSH(18, 18)
	e.fcvtSH(19, 19)
	e.fmulS(18, 18, 17)
	e.fmulS(19, 19, 17)
	e.scvtf4s(16, 16)
	e.fmlsLane(0, 16, 18, 0) // sumf -= dmin * mins-term
	// quants: halves of 128, four 2-bit fields each
	e.movi4s0(1)
	for j := 0; j < 2; j++ {
		e.ldurQ(20, 3, 16+32*j)
		e.ldurQ(21, 3, 32+32*j)
		for s := 0; s < 4; s++ {
			e.ldurQ(22, 4, 4+128*j+32*s)
			e.ldurQ(23, 4, 4+128*j+32*s+16)
			if s == 0 {
				e.and16(26, 20, 31)
				e.and16(27, 21, 31)
			} else {
				e.ushr16(26, 20, 2*s)
				e.ushr16(27, 21, 2*s)
				e.and16(26, 26, 31)
				e.and16(27, 27, 31)
			}
			e.movi4s0(28)
			e.movi4s0(29)
			e.sdot(28, 26, 22)
			e.sdot(29, 27, 23)
			is := 8*j + 2*s
			e.mlaLane(1, 28, 8+is/4, is%4)
			e.mlaLane(1, 29, 8+(is+1)/4, (is+1)%4)
		}
	}
	e.scvtf4s(1, 1)
	e.fmlaLane(0, 1, 19, 0) // sumf += d * sumi
	w("\tADD\t$%d, R3, R3", q2_KBlockBytes)
	w("\tADD\t$%d, R4, R4", q8_KBlockBytes)
	w("\tSUBW\t$1, R1, R1")
	w("\tCBNZW\tR1, q2kblk")
	w("q2kzero:")
	e.reduceStore(0, 2)
	w("\tRET")
	w("q2koob:")
	w("\tB\tovr_oob")
	return sb.String()
}
