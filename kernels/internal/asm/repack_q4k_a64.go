package asm

import (
	"fmt"
	"strings"
)

// Q4_K 8x8 repack kernels (ggml_gemv_q4_K_8x8_q8_K, exported by llama-wasm
// as dbg_gemv_q4_K_8x8): the decode-time matmul of a Q4_K tensor the
// wasm build repacks into block_q4_Kx8 (eight rows interleaved in
// 8-byte groups), against one block_q8_K activation row. The structure
// is llama.cpp's arm64 dotprod version: per 64-quant chunk the eight
// activation quads are broadcast so one SDOT scores a column pair
// (two lanes per column), pairs fold into column quads with ADDP, the
// 6-bit sub-block scales apply as i32 lane multiplies, and the mins
// term rides the activation block sums. FastMath only.
//
// Layouts (bytes). block_q4_Kx8 (1152): d[8] f16 (0) | dmin[8] f16 (16)
// | scales[96] (32): 12 packed bytes per sub-block 0..7 | qs[1024]
// (128): 16 groups g of 64 bytes, group g = bytes [8g, 8g+8) of each of
// the eight rows in row order; low nibbles are quants of sub-block
// 2(g/4), high nibbles of 2(g/4)+1. block_q8_K (292): d f32 (0) |
// qs[256] (4) | bsums[16] i16 (260).
//
// C signature (repack.h):
//
//	gemv(int n, float *s, size_t bs, const void *vx, const void *vy, int nr, int nc)
//
// nr is 1 by contract; s[x*8 + j] receives column j of group x.

const (
	q4Kx8BlockBytes = 1152
	q4Kx8ScalesOff  = 32
	q4Kx8QsOff      = 128
)

// kx8Layout describes a K-quant block repacked eight rows wide with the
// 6-bit scales/mins packing shared by q4_K and q5_K: block_q4_Kx8
// (1152) = d[8] | dmin[8] | scales[96] | qs[1024]; block_q5_Kx8 (1408)
// = d[8] | dmin[8] | scales[96] | qh[256] | qs[1024], where qh group k
// (64 bytes, the eight rows' qh bytes [8k, 8k+8)) carries bit 2c (low
// nibbles) and bit 2c+1 (high nibbles) of chunk c's quants.
type kx8Layout struct {
	name       string
	lbl        string // GEMV label prefix
	mlbl       string // GEMM label prefix
	tlbl       string // GEMM tile-loop label prefix (AVX2)
	scratch    string // GEMM frame scratch symbol
	blockBytes int
	scalesOff  int
	qsOff      int
	qhOff      int  // fifth bits (q5_K)
	fifth      bool // q5_K: quants carry a fifth bit from qh
}

var (
	q4Kx8Layout = kx8Layout{name: "q4_K", lbl: "gk", mlbl: "gm", tlbl: "gt", scratch: "q4kscratch", blockBytes: q4Kx8BlockBytes, scalesOff: q4Kx8ScalesOff, qsOff: q4Kx8QsOff}
	q5Kx8Layout = kx8Layout{name: "q5_K", lbl: "gk5", mlbl: "gm5", tlbl: "gt5", scratch: "q5kscratch", blockBytes: 1408, scalesOff: 32, qsOff: 384, qhOff: 128, fifth: true}
)

// q4Kx8ScalesMins decodes the 12 packed bytes at off(R<xr>) of one
// sub-block of a block_q4_Kx8 into the 8 mins (v<minsReg>.8b) and the 8
// scales (v<scReg>.8b) of its eight columns, through R13, R14, R15,
// R19, R22. The packing is get_scale_min_k4's, applied per column.
func (e *a64Q) q4Kx8ScalesMins(xr, off, minsReg, scReg int) {
	w := e.w
	w("\tMOVWU\t%d(R%d), R13", off, xr)
	w("\tMOVWU\t%d(R%d), R14", off+4, xr)
	w("\tMOVWU\t%d(R%d), R15", off+8, xr)
	// mins: lane0 = sm1 & 0x3f3f3f3f, lane1 = ((sm2>>4) & 0x0f0f0f0f) | (((sm1>>6) & 0x03030303) << 4)
	w("\tANDW\t$0x3f3f3f3f, R14, R19")
	w("\tLSRW\t$4, R15, R22")
	w("\tANDW\t$0x0f0f0f0f, R22, R22")
	w("\tLSRW\t$6, R14, R14")
	w("\tANDW\t$0x03030303, R14, R14")
	w("\tORRW\tR14<<4, R22, R22")
	w("\tORR\tR22<<32, R19, R19")
	e.fmovDX(minsReg, 19)
	// scales: lane0 = sm0 & 0x3f3f3f3f, lane1 = (sm2 & 0x0f0f0f0f) | (((sm0>>6) & 0x03030303) << 4)
	w("\tANDW\t$0x3f3f3f3f, R13, R19")
	w("\tANDW\t$0x0f0f0f0f, R15, R22")
	w("\tLSRW\t$6, R13, R14")
	w("\tANDW\t$0x03030303, R14, R14")
	w("\tORRW\tR14<<4, R22, R22")
	w("\tORR\tR22<<32, R19, R19")
	e.fmovDX(scReg, 19)
}

// smlalLaneH: d.4s += n.4h * m.h[idx] (m in v0..v15); smlal2LaneH the
// high half of n.
func (e *a64Q) smlalLaneH(d, n, m, idx int) {
	e.word(0x0F402000|uint32(idx>>2)<<11|uint32(idx>>1&1)<<21|uint32(idx&1)<<20|uint32(m)<<16|uint32(n)<<5|uint32(d), fmt.Sprintf("smlal v%d.4s, v%d.4h, v%d.h[%d]", d, n, m, idx))
}

func (e *a64Q) smlal2LaneH(d, n, m, idx int) {
	e.word(0x4F402000|uint32(idx>>2)<<11|uint32(idx>>1&1)<<21|uint32(idx&1)<<20|uint32(m)<<16|uint32(n)<<5|uint32(d), fmt.Sprintf("smlal2 v%d.4s, v%d.8h, v%d.h[%d]", d, n, m, idx))
}

func (e *a64Q) addp4s(d, n, m int) {
	e.word(0x4EA0BC00|lane3(d, n, m), fmt.Sprintf("addp v%d.4s, v%d.4s, v%d.4s", d, n, m))
}

func (e *a64Q) fmulLane(d, n, m, idx int) {
	e.word(0x4F809000|idxLH(idx)|lane3(d, n, m), fmt.Sprintf("fmul v%d.4s, v%d.4s, v%d.s[%d]", d, n, m, idx))
}

// a64GemvQ4K8x8Kernel emits the GEMV under sym.
//
// Registers: R1 nb, R2 s, R3 weight group (advancing), R4 activation
// row, R6 group stride, R7 groups left, R8 blocks left, R9/R10 the
// current weight/activation block, R11 = R10 + 256 (bsums), R12 the
// chunk's quant base. Vectors: v0/v1 f32 accumulators (columns 0-3,
// 4-7); v2/v3 d*yd, v28/v29 dmin*yd; v30/v7 i32 bias; v4/v5 mins,
// v12/v13 scales (i16, low/high sub-block of the chunk); v6 the eight
// activation sub-block sums; v16..v23 the chunk's activation quads
// (broadcast); v8..v11 SDOT accumulators; v14/v15/v24..v27 scratch;
// v31 = 0x0f.
func a64GemvQ4K8x8Kernel(sym string, wide bool) string {
	return a64GemvKx8Kernel(sym, wide, q4Kx8Layout)
}

// a64GemvQ5K8x8Kernel emits the q5_K GEMV: the q4_K body with the fifth
// bit of every quant merged from qh (bit 2c / 2c+1 of qh group k for
// chunk c), as in llama.cpp's arm64 gemv_q5_K_8x8_q8_K.
func a64GemvQ5K8x8Kernel(sym string, wide bool) string {
	return a64GemvKx8Kernel(sym, wide, q5Kx8Layout)
}

func a64GemvKx8Kernel(sym string, wide bool, L kx8Layout) string {
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

	w("// %s: %s 8x8 repack GEMV, SDOT over broadcast activation quads.", sym, L.name)
	w("\tMOVW\tl0+8(FP), R1")
	w("\tLSRW\t$8, R1, R1") // nb
	arg("l6", 7)
	w("\tLSRW\t$3, R7, R7") // column groups
	w("\tCBZW\tR7, %sdone", L.lbl)
	arg("l1", 2)
	w("\tLSL\t$5, R7, R26") // nc*4 bytes of output
	w("\tADD\tR2, R26, R26")
	w("\tCMP\tR26, R21")
	w("\tBLO\t%soob", L.lbl)
	arg("l3", 3)
	w("\tMOVD\t$%d, R6", L.blockBytes)
	w("\tMUL\tR1, R6, R6") // group stride = nb * 1152
	w("\tMUL\tR7, R6, R26")
	w("\tADD\tR3, R26, R26")
	w("\tCMP\tR26, R21")
	w("\tBLO\t%soob", L.lbl)
	arg("l4", 4)
	w("\tMOVD\t$%d, R26", q8_KBlockBytes)
	w("\tMUL\tR1, R26, R26")
	w("\tADD\tR4, R26, R26")
	w("\tCMP\tR26, R21")
	w("\tBLO\t%soob", L.lbl)
	w("\tADD\tR20, R2, R2")
	w("\tADD\tR20, R3, R3")
	w("\tADD\tR20, R4, R4")
	e.movi16(31, 15)

	w("%sgroup:", L.lbl)
	e.movi4s0(0)
	e.movi4s0(1)
	w("\tMOVD\tR3, R9")
	w("\tMOVD\tR4, R10")
	w("\tMOVW\tR1, R8")
	w("\tCBZW\tR8, %sstore", L.lbl)
	w("%sblk:", L.lbl)
	// the block's integer accumulators: sumi (v2 columns 0-3, v3 4-7)
	// and the mins bias (v30, v7); like the GEMM tile (and llama.cpp's
	// gemv) the whole super-block accumulates in i32 and converts once,
	// so the GEMV and GEMM paths agree bit for bit
	e.movi4s0(2)
	e.movi4s0(3)
	e.movi4s0(30)
	e.movi4s0(7)
	// activation sub-block sums: pairs of the 16 bsums
	w("\tADD\t$256, R10, R11")
	e.ldurQ(24, 11, 4)
	e.ldurQ(25, 11, 20)
	e.addp8h(6, 24, 25)
	for chunk := 0; chunk < 4; chunk++ {
		// scales and mins of the chunk's two sub-blocks (low / high nibbles)
		e.q4Kx8ScalesMins(9, L.scalesOff+chunk*24, 4, 12)
		e.q4Kx8ScalesMins(9, L.scalesOff+chunk*24+12, 5, 13)
		e.ushll8h(4, 4)
		e.ushll8h(5, 5)
		e.ushll8h(12, 12)
		e.ushll8h(13, 13)
		// the chunk's 64 activation quants as eight broadcast quads
		for k := 0; k < 8; k++ {
			e.ldurD(16+k, 10, 4+chunk*64+8*k)
			e.dup2d(16+k, 16+k, 0)
		}
		w("\tADD\t$%d, R9, R12", L.qsOff+chunk*256)
		if L.fifth {
			w("\tADD\t$%d, R9, R13", L.qhOff) // (the scale decoder clobbered R13)
		}
		for quad := 0; quad < 2; quad++ {
			for i := 8; i < 12; i++ {
				e.movi4s0(i)
			}
			if L.fifth {
				e.movi16(14, 1) // bit masks for the fifth bits (v14/v15 are
				e.movi16(15, 2) // fold scratch after the SDOTs)
			}
			for cp := 2 * quad; cp < 2*quad+2; cp++ {
				lo, hi := 8+cp-2*quad, 10+cp-2*quad
				for k := 0; k < 4; k++ {
					e.ldurQ(24, 12, 16*cp+64*k)
					e.and16(25, 24, 31)
					e.ushr16(26, 24, 4)
					if L.fifth {
						// fifth bits: qh group k, bit 2c -> low nibbles, bit 2c+1 -> high
						e.ldurQ(27, 13, 16*cp+64*k)
						if chunk > 0 {
							e.ushr16(27, 27, 2*chunk)
						}
						e.and16(24, 27, 14)
						e.shl16(24, 24, 4)
						e.orr16(25, 25, 24)
						e.and16(24, 27, 15)
						e.shl16(24, 24, 3)
						e.orr16(26, 26, 24)
					}
					e.sdot(lo, 25, 16+k)
					e.sdot(hi, 26, 20+k)
				}
			}
			acc := 2 + quad // i32 sumi of columns 4quad..4quad+3
			// low nibbles: sub-block 2chunk
			e.addp4s(14, 8, 9)
			if quad == 0 {
				e.ushll4s(15, 12)
			} else {
				e.ushll2_4s(15, 12)
			}
			e.mla4s(acc, 14, 15)
			// high nibbles: sub-block 2chunk+1
			e.addp4s(14, 10, 11)
			if quad == 0 {
				e.ushll4s(15, 13)
			} else {
				e.ushll2_4s(15, 13)
			}
			e.mla4s(acc, 14, 15)
		}
		// bias: sum(bsums) * mins per column, both sub-blocks of the chunk
		e.smlalLaneH(30, 4, 6, 2*chunk)
		e.smlalLaneH(30, 5, 6, 2*chunk+1)
		e.smlal2LaneH(7, 4, 6, 2*chunk)
		e.smlal2LaneH(7, 5, 6, 2*chunk+1)
	}
	// fold: acc += sumi * d*yd - bias * dmin*yd (the GEMM tile's order)
	e.ldurS(24, 10, 0)
	e.ldurD(25, 9, 0)
	e.fcvtl(28, 25)
	e.fmulLane(28, 28, 24, 0) // d*yd, columns 0-3
	e.ldurD(25, 9, 8)
	e.fcvtl(29, 25)
	e.fmulLane(29, 29, 24, 0) // columns 4-7
	e.scvtf4s(2, 2)
	e.scvtf4s(3, 3)
	e.fmla4s(0, 2, 28)
	e.fmla4s(1, 3, 29)
	e.ldurD(25, 9, 16)
	e.fcvtl(28, 25)
	e.fmulLane(28, 28, 24, 0) // dmin*yd, columns 0-3
	e.ldurD(25, 9, 24)
	e.fcvtl(29, 25)
	e.fmulLane(29, 29, 24, 0)
	e.scvtf4s(30, 30)
	e.scvtf4s(7, 7)
	e.fmls4s(0, 30, 28)
	e.fmls4s(1, 7, 29)
	w("\tADD\t$%d, R9, R9", L.blockBytes)
	w("\tADD\t$%d, R10, R10", q8_KBlockBytes)
	w("\tSUBW\t$1, R8, R8")
	w("\tCBNZW\tR8, %sblk", L.lbl)
	w("%sstore:", L.lbl)
	e.word(0x3C800000|uint32(0)<<12|uint32(2)<<5|uint32(0), "stur q0, [x2, #0]")
	e.word(0x3C800000|uint32(16)<<12|uint32(2)<<5|uint32(1), "stur q1, [x2, #16]")
	w("\tADD\t$32, R2, R2")
	w("\tADD\tR3, R6, R3")
	w("\tSUBW\t$1, R7, R7")
	w("\tCBNZW\tR7, %sgroup", L.lbl)
	w("%sdone:", L.lbl)
	w("\tRET")
	w("%soob:", L.lbl)
	w("\tB\tovr_oob")
	return sb.String()
}

// --- GEMM: four activation rows (block_q8_Kx4) against eight columns.
//
// block_q8_Kx4 (1168): d[4] f32 (0) | qs[1024] (16): 32 quarters of
// 32 bytes, quarter c = quants [8c, 8c+8) of rows 0..3 in row order |
// bsums[64] i16 (1040): quarter-major, bsums[16q + 4r + c] is row r's
// sum over quants [64q + 16c, +16).
//
// The tile is llama.cpp's arm64 i8mm structure: for each 64-quant chunk
// and column pair, SMMLA of the pair's 2x8 nibble matrix against the
// activation rows' 2x8 quads gives the 2x2 partial [c0r0, c0r1, c1r0,
// c1r1] directly from the repacked layouts (no zips), scaled by the
// sub-block scales as [s0, s0, s1, s1] lane multiplies into eight i32
// accumulators (column pair x row pair); the mins term is a separate
// pass over the eight sub-blocks' mins and the rows' block sums; both
// fold into f32 per row and column quad once per super-block.

const (
	q8Kx4BlockBytes = 1168
	q8Kx4QsOff      = 16
	q8Kx4BsumsOff   = 1040
	// scratch: 8 x [scales 8B | mins 8B] then 8 x f32x4 accumulators.
	a64GemmQ4KScratch = 256
	a64GemmQ4KFrame   = 16 + a64GemmQ4KScratch
)

func (e *a64Q) smmla(d, n, m int) {
	e.word(0x4E80A400|lane3(d, n, m), fmt.Sprintf("smmla v%d.4s, v%d.16b, v%d.16b", d, n, m))
}

func (e *a64Q) uzp1_4s(d, n, m int) {
	e.word(0x4E801800|lane3(d, n, m), fmt.Sprintf("uzp1 v%d.4s, v%d.4s, v%d.4s", d, n, m))
}

func (e *a64Q) uzp2_4s(d, n, m int) {
	e.word(0x4E805800|lane3(d, n, m), fmt.Sprintf("uzp2 v%d.4s, v%d.4s, v%d.4s", d, n, m))
}

func (e *a64Q) zip2_4s(d, n, m int) {
	e.word(0x4E807800|lane3(d, n, m), fmt.Sprintf("zip2 v%d.4s, v%d.4s, v%d.4s", d, n, m))
}

func (e *a64Q) mla4s(d, n, m int) {
	e.word(0x4EA09400|lane3(d, n, m), fmt.Sprintf("mla v%d.4s, v%d.4s, v%d.4s", d, n, m))
}

func (e *a64Q) sturD(rt, rn, imm int) {
	e.word(0xFC000000|uint32(imm&0x1FF)<<12|uint32(rn)<<5|uint32(rt), fmt.Sprintf("stur d%d, [x%d, #%d]", rt, rn, imm))
}

func (e *a64Q) sturQ(rt, rn, imm int) {
	e.word(0x3C800000|uint32(imm&0x1FF)<<12|uint32(rn)<<5|uint32(rt), fmt.Sprintf("stur q%d, [x%d, #%d]", rt, rn, imm))
}

// a64GemmQ4K8x8Kernel emits the GEMM under sym (i8mm).
//
// Registers: R1 nb, R2 s, R3 vx, R4 vy, R5 output row stride (bytes),
// R6 weight group stride, R7 column groups, R8 row groups left, R9/R10
// current weight/activation block, R11 blocks left, R12 chunk base,
// R14 bsums base, R23 scratch, R24 tile output, R25 column groups left,
// R0 weight group base for this row group. Vectors: v0..v7 the i32
// tile accumulators (column pair cp: rows 0/1 in v[cp], rows 2/3 in
// v[cp+4]); v8..v11 SMMLA partials; v12..v15 nibble bytes; v16/v17
// nibble temps; v18/v19 activation quads; v20/v21 block scales;
// v24..v29 scale widening; v31 = 0x0f.
func a64GemmQ4K8x8Kernel(sym string, wide bool) string {
	return a64GemmKx8Kernel(sym, wide, q4Kx8Layout)
}

// a64GemmQ5K8x8Kernel emits the q5_K GEMM: the q4_K tile with the fifth
// bits merged from qh (see a64GemvQ5K8x8Kernel).
func a64GemmQ5K8x8Kernel(sym string, wide bool) string {
	return a64GemmKx8Kernel(sym, wide, q5Kx8Layout)
}

func a64GemmKx8Kernel(sym string, wide bool, L kx8Layout) string {
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

	w("// %s: %s 8x8 repack GEMM, SMMLA 2x2 tiles over the interleaved layouts.", sym, L.name)
	w("\tMOVW\tl0+8(FP), R1")
	w("\tLSRW\t$8, R1, R1") // nb
	arg("l6", 7)
	w("\tLSRW\t$3, R7, R7") // column groups
	arg("l5", 8)
	w("\tLSRW\t$2, R8, R8") // row groups
	w("\tCBZW\tR7, %sdone", L.mlbl)
	w("\tCBZW\tR8, %sdone", L.mlbl)
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
	w("\tBLO\t%soob", L.mlbl)
	arg("l3", 3)
	w("\tMOVD\t$%d, R6", L.blockBytes)
	w("\tMUL\tR1, R6, R6")
	w("\tMUL\tR7, R6, R26")
	w("\tADD\tR3, R26, R26")
	w("\tCMP\tR26, R21")
	w("\tBLO\t%soob", L.mlbl)
	arg("l4", 4)
	w("\tMOVD\t$%d, R26", q8Kx4BlockBytes)
	w("\tMUL\tR1, R26, R26")
	w("\tMUL\tR8, R26, R26")
	w("\tADD\tR4, R26, R26")
	w("\tCMP\tR26, R21")
	w("\tBLO\t%soob", L.mlbl)
	w("\tADD\tR20, R2, R2")
	w("\tADD\tR20, R3, R3")
	w("\tADD\tR20, R4, R4")
	w("\tMOVD\t$%s-%d(SP), R23", L.scratch, a64GemmQ4KScratch)
	e.movi16(31, 15)

	// ---- row groups (4 activation rows each).
	w("%srows:", L.mlbl)
	w("\tMOVD\tR3, R0")  // weight groups restart per row group
	w("\tMOVD\tR2, R24") // output for column group 0 of this row group
	w("\tMOVW\tR7, R25")
	w("%scols:", L.mlbl)
	// zero the f32 tile accumulators in scratch
	e.movi4s0(8)
	for i := 0; i < 8; i++ {
		e.sturQ(8, 23, 128+16*i)
	}
	w("\tMOVD\tR0, R9")
	w("\tMOVD\tR4, R10")
	w("\tMOVW\tR1, R11")
	w("\tCBZW\tR11, %sstore", L.mlbl)
	w("%sblk:", L.mlbl)
	// A: decode the eight sub-blocks' scales and mins into scratch.
	for k := 0; k < 8; k++ {
		e.q4Kx8ScalesMins(9, L.scalesOff+12*k, 16, 17)
		e.sturD(17, 23, 16*k)
		e.sturD(16, 23, 16*k+8)
	}
	// B: the SMMLA tile.
	for i := 0; i < 8; i++ {
		e.movi4s0(i)
	}
	if L.fifth {
		w("\tADD\t$%d, R9, R13", L.qhOff) // qh base (R13 was the scale decoder's scratch)
		e.movi16(22, 1)                   // fifth-bit masks: v22/v23 are the bias
		e.movi16(23, 2)                   // accumulators of step C, so rebuilt per block
	}
	for chunk := 0; chunk < 4; chunk++ {
		// scales of sub-blocks 2chunk (low nibbles) and 2chunk+1 (high) as i32 lanes:
		// v26/v27 = low sub-block columns 0-3 / 4-7, v28/v29 = high sub-block.
		e.ldurD(24, 23, 16*(2*chunk))
		e.ushll8h(24, 24)
		e.ushll4s(26, 24)
		e.ushll2_4s(27, 24)
		e.ldurD(25, 23, 16*(2*chunk+1))
		e.ushll8h(25, 25)
		e.ushll4s(28, 25)
		e.ushll2_4s(29, 25)
		w("\tADD\t$%d, R9, R12", L.qsOff+chunk*256)
		w("\tADD\t$%d, R10, R14", q8Kx4QsOff+chunk*256)
		for cp := 0; cp < 4; cp++ {
			// block scales [s(2cp), s(2cp), s(2cp+1), s(2cp+1)] for low (v20) and high (v21)
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
			for k := 0; k < 4; k++ {
				e.ldurQ(12+k, 12, 16*cp+64*k)
			}
			for i := 8; i < 12; i++ {
				e.movi4s0(i)
			}
			for k := 0; k < 4; k++ {
				e.and16(16, 12+k, 31)
				e.ushr16(17, 12+k, 4)
				if L.fifth {
					e.ldurQ(24, 13, 16*cp+64*k)
					if chunk > 0 {
						e.ushr16(24, 24, 2*chunk)
					}
					e.and16(25, 24, 22)
					e.shl16(25, 25, 4)
					e.orr16(16, 16, 25)
					e.and16(25, 24, 23)
					e.shl16(25, 25, 3)
					e.orr16(17, 17, 25)
				}
				e.ldurQ(18, 14, 32*k)     // rows 0/1, quad k (low nibbles)
				e.ldurQ(19, 14, 32*k+16)  // rows 2/3
				e.smmla(8, 16, 18)        // c(2cp..2cp+1) x r0/r1, low
				e.smmla(10, 16, 19)       // rows 2/3, low
				e.ldurQ(18, 14, 32*(k+4)) // quad k+4 (high nibbles)
				e.ldurQ(19, 14, 32*(k+4)+16)
				e.smmla(9, 17, 18)
				e.smmla(11, 17, 19)
			}
			e.mla4s(cp, 8, 20)
			e.mla4s(cp, 9, 21)
			e.mla4s(cp+4, 10, 20)
			e.mla4s(cp+4, 11, 21)
		}
	}
	// C: bias per row and column quad: sum over sub-blocks of bsums * mins.
	// v8..v11 = quarter q's pair sums [r0 lo, r0 hi, r1 lo, r1 hi, ...]
	// (the by-element multiplier must sit in v0..v15); v16+2r / v17+2r
	// accumulate row r's columns 0-3 / 4-7.
	w("\tADD\t$%d, R10, R14", q8Kx4BsumsOff)
	for q := 0; q < 4; q++ {
		e.ldurQ(12, 14, 32*q)
		e.ldurQ(13, 14, 32*q+16)
		e.addp8h(8+q, 12, 13)
	}
	for i := 16; i < 24; i++ {
		e.movi4s0(i)
	}
	for k := 0; k < 8; k++ {
		e.ldurD(24, 23, 16*k+8)
		e.ushll8h(24, 24)
		q, i := k/2, k%2
		for r := 0; r < 4; r++ {
			e.smlalLaneH(16+2*r, 24, 8+q, 2*r+i)
			e.smlal2LaneH(17+2*r, 24, 8+q, 2*r+i)
		}
	}
	// D: fold into the f32 tile in scratch. Row r quad j from the i32 tile:
	// uzp1/uzp2 of (v[2j], v[2j+1]) for rows 0/1, (v[2j+4], v[2j+5]) for rows 2/3.
	e.ldurD(28, 9, 0)
	e.fcvtl(28, 28) // d cols 0-3
	e.ldurD(29, 9, 8)
	e.fcvtl(29, 29) // d cols 4-7
	e.ldurD(30, 9, 16)
	e.fcvtl(30, 30) // dmin cols 0-3
	e.ldurD(31, 9, 24)
	e.fcvtl(31, 31) // dmin cols 4-7 (v31 = 0x0f is rebuilt per block)
	for r := 0; r < 4; r++ {
		e.ldurS(25, 10, 4*r) // activation row scale
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
			e.scvtf4s(13, 16+2*r+j)
			dv, dm := 28, 30
			if j == 1 {
				dv, dm = 29, 31
			}
			e.fmulLane(14, dv, 25, 0)
			e.fmulLane(15, dm, 25, 0)
			e.ldurQ(24, 23, 128+16*(2*r+j))
			e.fmla4s(24, 12, 14)
			e.fmls4s(24, 13, 15)
			e.sturQ(24, 23, 128+16*(2*r+j))
		}
	}
	e.movi16(31, 15)
	w("\tADD\t$%d, R9, R9", L.blockBytes)
	w("\tADD\t$%d, R10, R10", q8Kx4BlockBytes)
	w("\tSUBW\t$1, R11, R11")
	w("\tCBNZW\tR11, %sblk", L.mlbl)
	w("%sstore:", L.mlbl)
	// s[(row) * bs + col]: rows of this group at R24 + r*R5.
	w("\tMOVD\tR24, R12")
	for r := 0; r < 4; r++ {
		e.ldurQ(16, 23, 128+16*(2*r))
		e.ldurQ(17, 23, 128+16*(2*r+1))
		e.sturQ(16, 12, 0)
		e.sturQ(17, 12, 16)
		if r < 3 {
			w("\tADD\tR12, R5, R12")
		}
	}
	w("\tADD\t$32, R24, R24")
	w("\tADD\tR0, R6, R0")
	w("\tSUBW\t$1, R25, R25")
	w("\tCBNZW\tR25, %scols", L.mlbl)
	// next row group: activations advance by nb blocks, outputs by 4 rows
	w("\tMOVD\t$%d, R26", q8Kx4BlockBytes)
	w("\tMUL\tR1, R26, R26")
	w("\tADD\tR4, R26, R4")
	w("\tLSL\t$2, R5, R26")
	w("\tADD\tR2, R26, R2")
	w("\tSUBW\t$1, R8, R8")
	w("\tCBNZW\tR8, %srows", L.mlbl)
	w("%sdone:", L.mlbl)
	w("\tRET")
	w("%soob:", L.mlbl)
	w("\tB\tovr_oob")
	return sb.String()
}
