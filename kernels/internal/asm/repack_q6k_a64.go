package asm

import (
	"fmt"
	"strings"
)

// Q6_K 8x8 repack kernels (ggml_gemv_q6_K_8x8_q8_K, exported by llama-wasm
// as dbg_gemv_q6_K_8x8): the decode-time matmul of a Q6_K tensor the
// wasm build repacks into block_q6_Kx8 (eight rows interleaved in
// 8-byte groups), against one block_q8_K activation row. The structure
// is llama.cpp's arm64 dotprod version: the 6-bit quants are rebuilt
// unsigned (low nibble from ql, two high bits from qh), per 16-quant
// sub-block the activation quads are broadcast so one SDOT pair scores
// a column pair (two lanes per column), pairs fold into column quads
// with ADDP, the i8 sub-block scales apply as i32 lane multiplies, and
// the -32 offset rides the activation block sums. FastMath only.
//
// Layouts (bytes). block_q6_Kx8 (1680): d[8] f16 (0) | scales[128] i8
// (16): scales[8j + col] for sub-block j | ql[1024] (144): 16 groups g
// of 64 bytes, group g = ql bytes [8g, 8g+8) of each of the eight rows
// in row order | qh[512] (1168): 8 groups of 64 bytes likewise. In a
// plain row, half h (128 quants) is ql[64h..64h+64) and qh[32h..32h+32):
// quant 32k + l of the half (k = 0..3) is ql[64h + 32(k&1) + l] low
// (k < 2) or high (k >= 2) nibble, with qh[32h + l] bits 2k, 2k+1 as
// its top two bits. block_q8_K (292): d f32 (0) | qs[256] (4) |
// bsums[16] i16 (260).
//
// C signature (repack.h):
//
//	gemv(int n, float *s, size_t bs, const void *vx, const void *vy, int nr, int nc)
//
// nr is 1 by contract; s[x*8 + j] receives column j of group x.

const (
	q6Kx8BlockBytes = 1680
	q6Kx8ScalesOff  = 16
	q6Kx8QlOff      = 144
	q6Kx8QhOff      = 1168
)

// a64GemvQ6K8x8Kernel emits the GEMV under sym.
//
// Registers: R1 nb, R2 s, R3 weight group (advancing), R4 activation
// row, R6 group stride, R7 groups left, R8 blocks left, R9/R10 the
// current weight/activation block, R11 = R10 + 256 (bsums), R12/R13 the
// chunk's ql/qh base. Vectors: v0/v1 f32 accumulators (columns 0-3,
// 4-7); v2/v3 d*yd; v30/v7 i32 accumulators; v4/v5 i32 bias
// accumulators; v6 the activation sub-block sums of the current half
// (i16); v16..v19 the chunk's activation quads (broadcast); v8..v11
// SDOT accumulators of the low quants per column pair, v12..v15 of the
// high quants; v20..v25 scratch; v31 = 0x0f, v29 = 0x03, v28 = 0x30.
func a64GemvQ6K8x8Kernel(sym string, wide bool) string {
	var sb strings.Builder
	e := newA64Q(&sb)
	w := e.w
	argOff, _ := repackGemmArgs(wide)
	movArg := "MOVWU"
	if wide {
		movArg = "MOVD"
	}
	arg := func(name string, reg int) {
		mv := movArg
		if name == "l5" || name == "l6" {
			mv = "MOVWU"
		}
		w("\t%s\t%s+%d(FP), R%d", mv, name, argOff[name], reg)
	}

	w("// %s: q6_K 8x8 repack GEMV, SDOT over broadcast activation quads.", sym)
	w("\tMOVW\tl0+8(FP), R1")
	w("\tLSRW\t$8, R1, R1") // nb
	arg("l6", 7)
	w("\tLSRW\t$3, R7, R7") // column groups
	w("\tCBZW\tR7, g6done")
	arg("l1", 2)
	w("\tLSL\t$5, R7, R26") // nc*4 bytes of output
	w("\tADD\tR2, R26, R26")
	w("\tCMP\tR26, R21")
	w("\tBLO\tg6oob")
	arg("l3", 3)
	w("\tMOVD\t$%d, R6", q6Kx8BlockBytes)
	w("\tMUL\tR1, R6, R6") // group stride = nb * 1680
	w("\tMUL\tR7, R6, R26")
	w("\tADD\tR3, R26, R26")
	w("\tCMP\tR26, R21")
	w("\tBLO\tg6oob")
	arg("l4", 4)
	w("\tMOVD\t$%d, R26", q8_KBlockBytes)
	w("\tMUL\tR1, R26, R26")
	w("\tADD\tR4, R26, R26")
	w("\tCMP\tR26, R21")
	w("\tBLO\tg6oob")
	w("\tADD\tR20, R2, R2")
	w("\tADD\tR20, R3, R3")
	w("\tADD\tR20, R4, R4")
	e.movi16(31, 15)
	e.movi16(29, 3)
	e.movi16(28, 0x30)

	w("g6group:")
	e.movi4s0(0)
	e.movi4s0(1)
	w("\tMOVD\tR3, R9")
	w("\tMOVD\tR4, R10")
	w("\tMOVW\tR1, R8")
	w("\tCBZW\tR8, g6store")
	w("g6blk:")
	// per-block scale vectors: d*yd (v2, v3)
	e.ldurS(24, 10, 0)
	e.ldurD(25, 9, 0)
	e.fcvtl(2, 25)
	e.fmulLane(2, 2, 24, 0)
	e.ldurD(25, 9, 8)
	e.fcvtl(3, 25)
	e.fmulLane(3, 3, 24, 0)
	w("\tADD\t$256, R10, R11")
	e.movi4s0(30)
	e.movi4s0(7)
	e.movi4s0(4)
	e.movi4s0(5)
	for half := 0; half < 2; half++ {
		// the half's eight activation sub-block sums
		e.ldurQ(6, 11, 4+16*half)
		for sbk := 0; sbk < 4; sbk++ {
			// activation quants [128h + 16sb, +16) low and +64 high, as
			// broadcast quads
			aoff := 4 + 128*half + 16*sbk
			e.ldurD(16, 10, aoff)
			e.dup2d(16, 16, 0)
			e.ldurD(17, 10, aoff+8)
			e.dup2d(17, 17, 0)
			e.ldurD(18, 10, aoff+64)
			e.dup2d(18, 18, 0)
			e.ldurD(19, 10, aoff+72)
			e.dup2d(19, 19, 0)
			w("\tADD\t$%d, R9, R12", q6Kx8QlOff+512*half+128*sbk)
			w("\tADD\t$%d, R9, R13", q6Kx8QhOff+256*half+128*(sbk&1))
			for i := 8; i < 16; i++ {
				e.movi4s0(i)
			}
			for cp := 0; cp < 4; cp++ {
				e.ldurQ(20, 12, 16*cp)    // ql, quants 0..7 of the 16
				e.ldurQ(21, 12, 64+16*cp) // ql, quants 8..15
				e.ldurQ(22, 13, 16*cp)    // qh
				e.ldurQ(23, 13, 64+16*cp)
				if sbk >= 2 {
					e.ushr16(22, 22, 2)
					e.ushr16(23, 23, 2)
				}
				// low quants: (ql & 0xf) | (qh & 3) << 4
				e.and16(24, 20, 31)
				e.and16(25, 22, 29)
				e.shl16(25, 25, 4)
				e.orr16(24, 24, 25)
				// high quants: (ql >> 4) | (qh & 0x30)
				e.ushr16(20, 20, 4)
				e.and16(22, 22, 28)
				e.orr16(20, 20, 22)
				e.sdot(8+cp, 24, 16)
				e.sdot(12+cp, 20, 18)
				e.and16(25, 21, 31)
				e.and16(22, 23, 29)
				e.shl16(22, 22, 4)
				e.orr16(25, 25, 22)
				e.ushr16(21, 21, 4)
				e.and16(23, 23, 28)
				e.orr16(21, 21, 23)
				e.sdot(8+cp, 25, 17)
				e.sdot(12+cp, 21, 19)
			}
			// fold column pairs into column quads
			e.addp4s(20, 8, 9)   // low, columns 0-3
			e.addp4s(21, 10, 11) // low, columns 4-7
			e.addp4s(22, 12, 13) // high, columns 0-3
			e.addp4s(23, 14, 15) // high, columns 4-7
			// sub-block scales j = 8h + sb (low quants) and j + 4 (high)
			jl := 8*half + sbk
			e.ldurD(24, 9, q6Kx8ScalesOff+8*jl)
			e.ldurD(25, 9, q6Kx8ScalesOff+8*(jl+4))
			e.sshll8h(24, 24)
			e.sshll8h(25, 25)
			e.sshll4s(8, 24)
			e.mla4s(30, 20, 8)
			e.sshll2_4s(8, 24)
			e.mla4s(7, 21, 8)
			e.sshll4s(8, 25)
			e.mla4s(30, 22, 8)
			e.sshll2_4s(8, 25)
			e.mla4s(7, 23, 8)
			// bias: sum over sub-blocks of scale * bsum per column
			e.smlalLaneH(4, 24, 6, sbk)
			e.smlal2LaneH(5, 24, 6, sbk)
			e.smlalLaneH(4, 25, 6, sbk+4)
			e.smlal2LaneH(5, 25, 6, sbk+4)
		}
	}
	// acc -= 32 * bias; f32 accumulate scaled by d*yd
	e.shl4s(4, 4, 5)
	e.shl4s(5, 5, 5)
	e.sub4s(30, 30, 4)
	e.sub4s(7, 7, 5)
	e.scvtf4s(30, 30)
	e.scvtf4s(7, 7)
	e.fmla4s(0, 30, 2)
	e.fmla4s(1, 7, 3)
	w("\tADD\t$%d, R9, R9", q6Kx8BlockBytes)
	w("\tADD\t$%d, R10, R10", q8_KBlockBytes)
	w("\tSUBW\t$1, R8, R8")
	w("\tCBNZW\tR8, g6blk")
	w("g6store:")
	e.sturQ(0, 2, 0)
	e.sturQ(1, 2, 16)
	w("\tADD\t$32, R2, R2")
	w("\tADD\tR3, R6, R3")
	w("\tSUBW\t$1, R7, R7")
	w("\tCBNZW\tR7, g6group")
	w("g6done:")
	w("\tRET")
	w("g6oob:")
	w("\tB\tovr_oob")
	return sb.String()
}

// --- GEMM: four activation rows (block_q8_Kx4) against eight columns.
//
// block_q8_Kx4: see repack_q4k_a64.go. The tile is llama.cpp's arm64
// i8mm structure: per 16-quant sub-block and column pair, SMMLA of the
// pair's 2x8 signed quants (rebuilt from ql/qh, minus 32) against the
// activation rows' 2x8 quads gives the 2x2 partial [c0r0, c0r1, c1r0,
// c1r1] directly from the repacked layouts, scaled by the sub-block
// scales as [s0, s0, s1, s1] lane multiplies into eight i32
// accumulators (column pair x row pair); with the quants already
// centred there is no block-sum term. Folds into f32 per row and
// column quad once per super-block.

const (
	// scratch: 8 x f32x4 tile accumulators.
	a64GemmQ6KScratch = 128
	a64GemmQ6KFrame   = 16 + a64GemmQ6KScratch
)

// a64GemmQ6K8x8Kernel emits the GEMM under sym (i8mm).
//
// Registers: R1 nb, R2 s, R3 vx, R4 vy, R5 output row stride (bytes),
// R6 weight group stride, R7 column groups, R8 row groups left, R9/R10
// current weight/activation block, R11 blocks left, R12/R13 the chunk's
// ql/qh base, R14/R15 the chunk's low/high activation quarters, R23
// scratch, R24 tile output, R25 column groups left, R0 weight group
// base for this row group. Vectors: v0..v7 the i32 tile accumulators
// (column pair cp: rows 0/1 in v[cp], rows 2/3 in v[cp+4]); v8..v11
// SMMLA partials; v12..v17 quant bytes; v18/v19 activation quads;
// v20/v21 scale pairs; v24 scratch; v26..v29 widened scales; v31 =
// 0x0f, v22 = 0x03, v23 = 0x30, v25 = 32.
func a64GemmQ6K8x8Kernel(sym string, wide bool) string {
	var sb strings.Builder
	e := newA64Q(&sb)
	w := e.w
	argOff, _ := repackGemmArgs(wide)
	movArg := "MOVWU"
	if wide {
		movArg = "MOVD"
	}
	arg := func(name string, reg int) {
		mv := movArg
		if name == "l5" || name == "l6" {
			mv = "MOVWU"
		}
		w("\t%s\t%s+%d(FP), R%d", mv, name, argOff[name], reg)
	}

	w("// %s: q6_K 8x8 repack GEMM, SMMLA 2x2 tiles over the interleaved layouts.", sym)
	w("\tMOVW\tl0+8(FP), R1")
	w("\tLSRW\t$8, R1, R1") // nb
	arg("l6", 7)
	w("\tLSRW\t$3, R7, R7") // column groups
	arg("l5", 8)
	w("\tLSRW\t$2, R8, R8") // row groups
	w("\tCBZW\tR7, m6done")
	w("\tCBZW\tR8, m6done")
	arg("l1", 2)
	arg("l2", 5)
	w("\tLSL\t$2, R5, R5") // bs floats -> bytes
	// s + (nr-1)*bs*4 + nc*4
	w("\tLSL\t$2, R8, R26")
	w("\tSUB\t$1, R26, R26")
	w("\tMUL\tR26, R5, R26")
	w("\tADD\tR2, R26, R26")
	w("\tADD\tR7<<5, R26, R26")
	w("\tCMP\tR26, R21")
	w("\tBLO\tm6oob")
	arg("l3", 3)
	w("\tMOVD\t$%d, R6", q6Kx8BlockBytes)
	w("\tMUL\tR1, R6, R6")
	w("\tMUL\tR7, R6, R26")
	w("\tADD\tR3, R26, R26")
	w("\tCMP\tR26, R21")
	w("\tBLO\tm6oob")
	arg("l4", 4)
	w("\tMOVD\t$%d, R26", q8Kx4BlockBytes)
	w("\tMUL\tR1, R26, R26")
	w("\tMUL\tR8, R26, R26")
	w("\tADD\tR4, R26, R26")
	w("\tCMP\tR26, R21")
	w("\tBLO\tm6oob")
	w("\tADD\tR20, R2, R2")
	w("\tADD\tR20, R3, R3")
	w("\tADD\tR20, R4, R4")
	w("\tMOVD\t$q6kscratch-%d(SP), R23", a64GemmQ6KScratch)
	e.movi16(31, 15)
	e.movi16(22, 3)
	e.movi16(23, 0x30)
	e.movi16(25, 32)

	// ---- row groups (4 activation rows each).
	w("m6rows:")
	w("\tMOVD\tR3, R0")  // weight groups restart per row group
	w("\tMOVD\tR2, R24") // output for column group 0 of this row group
	w("\tMOVW\tR7, R25")
	w("m6cols:")
	// zero the f32 tile accumulators in scratch
	e.movi4s0(8)
	for i := 0; i < 8; i++ {
		e.sturQ(8, 23, 16*i)
	}
	w("\tMOVD\tR0, R9")
	w("\tMOVD\tR4, R10")
	w("\tMOVW\tR1, R11")
	w("\tCBZW\tR11, m6store")
	w("m6blk:")
	for i := 0; i < 8; i++ {
		e.movi4s0(i)
	}
	for half := 0; half < 2; half++ {
		for sbk := 0; sbk < 4; sbk++ {
			w("\tADD\t$%d, R9, R12", q6Kx8QlOff+512*half+128*sbk)
			w("\tADD\t$%d, R9, R13", q6Kx8QhOff+256*half+128*(sbk&1))
			w("\tADD\t$%d, R10, R14", q8Kx4QsOff+512*half+64*sbk) // low quarters
			w("\tADD\t$256, R14, R15")                            // high quarters
			// sub-block scales j = 8h + sb (low quants) and j + 4 (high) as
			// i32 lanes: v26/v27 = low, columns 0-3 / 4-7; v28/v29 = high
			jl := 8*half + sbk
			e.ldurD(24, 9, q6Kx8ScalesOff+8*jl)
			e.sshll8h(24, 24)
			e.sshll4s(26, 24)
			e.sshll2_4s(27, 24)
			e.ldurD(24, 9, q6Kx8ScalesOff+8*(jl+4))
			e.sshll8h(24, 24)
			e.sshll4s(28, 24)
			e.sshll2_4s(29, 24)
			for cp := 0; cp < 4; cp++ {
				lo, hi := 26, 28
				if cp >= 2 {
					lo, hi = 27, 29
				}
				if cp%2 == 0 {
					e.zip1_4s(20, lo, lo)
					e.zip1_4s(21, hi, hi)
				} else {
					e.zip2_4s(20, lo, lo)
					e.zip2_4s(21, hi, hi)
				}
				e.ldurQ(12, 12, 16*cp)    // ql, quants 0..7 of the 16
				e.ldurQ(13, 12, 64+16*cp) // ql, quants 8..15
				e.ldurQ(14, 13, 16*cp)    // qh
				e.ldurQ(15, 13, 64+16*cp)
				if sbk >= 2 {
					e.ushr16(14, 14, 2)
					e.ushr16(15, 15, 2)
				}
				// low quants (v16, v17) and high quants (v12, v13), centred
				e.and16(16, 12, 31)
				e.and16(17, 14, 22)
				e.shl16(17, 17, 4)
				e.orr16(16, 16, 17)
				e.sub16(16, 16, 25)
				e.ushr16(12, 12, 4)
				e.and16(14, 14, 23)
				e.orr16(12, 12, 14)
				e.sub16(12, 12, 25)
				e.and16(17, 13, 31)
				e.and16(14, 15, 22)
				e.shl16(14, 14, 4)
				e.orr16(17, 17, 14)
				e.sub16(17, 17, 25)
				e.ushr16(13, 13, 4)
				e.and16(15, 15, 23)
				e.orr16(13, 13, 15)
				e.sub16(13, 13, 25)
				for i := 8; i < 12; i++ {
					e.movi4s0(i)
				}
				e.ldurQ(18, 14, 0)  // rows 0/1, quants 0..7 (low)
				e.ldurQ(19, 14, 16) // rows 2/3
				e.smmla(8, 16, 18)
				e.smmla(10, 16, 19)
				e.ldurQ(18, 14, 32) // quants 8..15
				e.ldurQ(19, 14, 48)
				e.smmla(8, 17, 18)
				e.smmla(10, 17, 19)
				e.ldurQ(18, 15, 0) // high quants
				e.ldurQ(19, 15, 16)
				e.smmla(9, 12, 18)
				e.smmla(11, 12, 19)
				e.ldurQ(18, 15, 32)
				e.ldurQ(19, 15, 48)
				e.smmla(9, 13, 18)
				e.smmla(11, 13, 19)
				e.mla4s(cp, 8, 20)
				e.mla4s(cp, 9, 21)
				e.mla4s(cp+4, 10, 20)
				e.mla4s(cp+4, 11, 21)
			}
		}
	}
	// fold into the f32 tile in scratch. Row r quad j from the i32 tile:
	// uzp1/uzp2 of (v[2j], v[2j+1]) for rows 0/1, (v[2j+4], v[2j+5]) for rows 2/3.
	e.ldurD(28, 9, 0)
	e.fcvtl(28, 28) // d cols 0-3
	e.ldurD(29, 9, 8)
	e.fcvtl(29, 29) // d cols 4-7
	for r := 0; r < 4; r++ {
		e.ldurS(30, 10, 4*r) // activation row scale
		for j := 0; j < 2; j++ {
			a, b := 2*j, 2*j+1
			if r >= 2 {
				a, b = 2*j+4, 2*j+5
			}
			if r%2 == 0 {
				e.uzp1_4s(12, a, b)
			} else {
				e.uzp2_4s(12, a, b)
			}
			e.scvtf4s(12, 12)
			dv := 28
			if j == 1 {
				dv = 29
			}
			e.fmulLane(14, dv, 30, 0)
			e.ldurQ(24, 23, 16*(2*r+j))
			e.fmla4s(24, 12, 14)
			e.sturQ(24, 23, 16*(2*r+j))
		}
	}
	w("\tADD\t$%d, R9, R9", q6Kx8BlockBytes)
	w("\tADD\t$%d, R10, R10", q8Kx4BlockBytes)
	w("\tSUBW\t$1, R11, R11")
	w("\tCBNZW\tR11, m6blk")
	w("m6store:")
	// s[(row) * bs + col]: rows of this group at R24 + r*R5.
	w("\tMOVD\tR24, R12")
	for r := 0; r < 4; r++ {
		e.ldurQ(16, 23, 16*(2*r))
		e.ldurQ(17, 23, 16*(2*r+1))
		e.sturQ(16, 12, 0)
		e.sturQ(17, 12, 16)
		if r < 3 {
			w("\tADD\tR12, R5, R12")
		}
	}
	w("\tADD\t$32, R24, R24")
	w("\tADD\tR0, R6, R0")
	w("\tSUBW\t$1, R25, R25")
	w("\tCBNZW\tR25, m6cols")
	// next row group: activations advance by nb blocks, outputs by 4 rows
	w("\tMOVD\t$%d, R26", q8Kx4BlockBytes)
	w("\tMUL\tR1, R26, R26")
	w("\tADD\tR4, R26, R4")
	w("\tLSL\t$2, R5, R26")
	w("\tADD\tR2, R26, R2")
	w("\tSUBW\t$1, R8, R8")
	w("\tCBNZW\tR8, m6rows")
	w("m6done:")
	w("\tRET")
	w("m6oob:")
	w("\tB\tovr_oob")
	return sb.String()
}

var _ = fmt.Sprintf
