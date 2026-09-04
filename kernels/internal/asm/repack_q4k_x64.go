package asm

import (
	"fmt"
	"strings"
)

// amd64 (AVX2) bodies of the Q4_K 8x8 repack GEMV and GEMM. One
// activation row at a time (the GEMM runs its four rows as four passes
// over the same weight group, which stays in L1): per 64-quant chunk
// the 8-byte activation quads are broadcast to every 64-bit lane, so
// VPMADDUBSW against the 32 low (or high) nibbles of four columns
// yields four i16 pair sums per column; the four quads of a sub-block
// accumulate in i16 (at most 15240), VPMADDWD folds to i32, VPHADDD
// folds the two column halves into eight lanes in the order
// [c0 c1 c4 c5 c2 c3 c6 c7], the 6-bit sub-block scales apply as i32
// lane multiplies, and the mins term is VPMADDWD of the per-column
// (min_lo, min_hi) pairs against the sub-block's (bsum_lo, bsum_hi)
// pair. Both accumulate in f32 per super-block and are permuted back to
// column order at the store. FastMath only.
//
// Layouts: see repack_q4k_a64.go. Constants: x64Q4KConsts.

// x64Q4KConsts:
//
//	 0: 32 x 0x0f
//	32: 16 x i16 1
//	64: VPSHUFB index (xmm): scale bytes [s0..s7] -> [s0 s1 s4 s5 s2 s3 s6 s7] then zero
//	80: VPERMPS index: [0 1 4 5 2 3 6 7] -> column order
func x64Q4KConsts() []byte {
	c := make([]byte, 112)
	for i := 0; i < 32; i++ {
		c[i] = 0x0f
	}
	for i := 0; i < 16; i++ {
		c[32+2*i] = 1
	}
	order := []byte{0, 1, 4, 5, 2, 3, 6, 7}
	for i := 0; i < 8; i++ {
		c[64+i] = order[i]
	}
	for i := 8; i < 16; i++ {
		c[64+i] = 0x80 // zero
	}
	for i := 0; i < 8; i++ {
		c[80+4*i] = order[i]
	}
	return c
}

const (
	x64q4kLow  = 0
	x64q4kOnes = 32
	x64q4kShuf = 64
	x64q4kPerm = 80
	// frame: 0 bsum pairs (16) | 16 vx | 24 activation base | 32 tile output
	// base | 40 column groups left | 48 row groups left | 56 bs bytes |
	// 64 group stride.
	x64Q4KFrame = 80
	// tiled GEMM frame: 0 bsum pairs of the four rows (4 x 16) | 64 half-0
	// i32 partials (4 x 32) | 192 sumi accumulators (4 x 32) | 320 bias
	// accumulators (4 x 32) | 448 f32 accumulators (4 x 32) | 576 vx |
	// 584 activation base | 592 tile output | 600 column groups left |
	// 608 row groups left | 616 bs bytes | 624 group stride | 632 column
	// groups left.
	x64Q4KTileFrame = 640
)

// x64Q4KScalesMins decodes the 12 packed bytes at off(reg) into R13 =
// scales 0..3 | scales 4..7 << 32 and R10 = mins likewise (eight bytes
// each), through R12, R13, BX, R11 and AX. reg is left alone (the
// callers pass the weight block pointer in R9).
func x64Q4KScalesMins(w func(string, ...any), reg string, off int) {
	w("\tMOVL\t%d(%s), R12", off, reg)   // sm0
	w("\tMOVL\t%d(%s), R13", off+4, reg) // sm1
	w("\tMOVL\t%d(%s), BX", off+8, reg)  // sm2
	// mins: lo = sm1 & 0x3f3f3f3f; hi = ((sm2>>4)&0x0f0f0f0f) | (((sm1>>6)&0x03030303)<<4)
	w("\tMOVL\tR13, R10")
	w("\tANDL\t$0x3f3f3f3f, R10")
	w("\tMOVL\tBX, R11")
	w("\tSHRL\t$4, R11")
	w("\tANDL\t$0x0f0f0f0f, R11")
	w("\tMOVL\tR13, AX")
	w("\tSHRL\t$6, AX")
	w("\tANDL\t$0x03030303, AX")
	w("\tSHLL\t$4, AX")
	w("\tORL\tAX, R11")
	w("\tSHLQ\t$32, R11")
	w("\tORQ\tR11, R10")
	// scales: lo = sm0 & 0x3f3f3f3f; hi = (sm2 & 0x0f0f0f0f) | (((sm0>>6)&0x03030303)<<4)
	w("\tMOVL\tR12, R13")
	w("\tANDL\t$0x3f3f3f3f, R13")
	w("\tMOVL\tBX, R11")
	w("\tANDL\t$0x0f0f0f0f, R11")
	w("\tMOVL\tR12, AX")
	w("\tSHRL\t$6, AX")
	w("\tANDL\t$0x03030303, AX")
	w("\tSHLL\t$4, AX")
	w("\tORL\tAX, R11")
	w("\tSHLQ\t$32, R11")
	w("\tORQ\tR11, R13")
}

// x64Q4K8x8Body emits the per-column-group body shared by the GEMV and
// the GEMM passes. On entry: SI = weight group, DX = activation block
// base (advancing per block), CX = nb, DI = output for the eight
// columns; R14/R15 the memory contract. gemm selects the block_q8_Kx4
// activation addressing for row `row` (quads at 16 + 32g + 8row, block
// sums quarter-major, scale d[row]); otherwise the plain block_q8_K
// layout. Y8 = 0x0f, Y9 = ones i16, X10 = shuffle, Y11 = permute
// (loaded by the caller). Clobbers Y0..Y7, Y12..Y15, AX, BX, R8..R13.
func x64Q4K8x8Body(w func(string, ...any), lbl string, gemm bool, row int) {
	actBlock := q8_KBlockBytes
	if gemm {
		actBlock = q8Kx4BlockBytes
	}
	w("\tVXORPS\tY0, Y0, Y0") // sum
	w("\tVXORPS\tY1, Y1, Y1") // mins term
	w("\tMOVQ\tCX, R8")
	w("\tMOVQ\tSI, R9")
	w("%sblk:", lbl)
	// row scale, column scales (f16 -> f32) as [c0..c7]; keep both in hadd order
	// by permuting once here (the permute is its own inverse).
	if gemm {
		w("\tVBROADCASTSS\t%d(DX), Y12", 4*row)
	} else {
		w("\tVBROADCASTSS\t(DX), Y12")
	}
	w("\tVCVTPH2PS\t(R9), Y13")
	w("\tVPERMPS\tY13, Y11, Y13")
	w("\tVMULPS\tY12, Y13, Y13") // d * yd, hadd order
	w("\tVCVTPH2PS\t16(R9), Y14")
	w("\tVPERMPS\tY14, Y11, Y14")
	w("\tVMULPS\tY12, Y14, Y14") // dmin * yd, hadd order
	// block-sum pairs of the eight sub-blocks -> 8 x i16 on the frame
	if gemm {
		// quarter-major: row's four sums per quarter at 1040 + 32q + 8row
		for q := 0; q < 4; q++ {
			w("\tMOVWLSX\t%d(DX), AX", q8Kx4BsumsOff+32*q+8*row)
			w("\tMOVWLSX\t%d(DX), BX", q8Kx4BsumsOff+32*q+8*row+2)
			w("\tADDL\tBX, AX")
			w("\tMOVW\tAX, %d(SP)", 4*q)
			w("\tMOVWLSX\t%d(DX), AX", q8Kx4BsumsOff+32*q+8*row+4)
			w("\tMOVWLSX\t%d(DX), BX", q8Kx4BsumsOff+32*q+8*row+6)
			w("\tADDL\tBX, AX")
			w("\tMOVW\tAX, %d(SP)", 4*q+2)
		}
	} else {
		w("\tVMOVDQU\t260(DX), X2")
		w("\tVMOVDQU\t276(DX), X3")
		w("\tVPHADDW\tX3, X2, X2")
		w("\tVMOVDQU\tX2, (SP)")
	}
	w("\tVPXOR\tY4, Y4, Y4") // sumi (i32, hadd order)
	w("\tVPXOR\tY5, Y5, Y5") // bias (i32, hadd order)
	for sb := 0; sb < 4; sb++ {
		// scales/mins of sub-blocks 2sb (low) and 2sb+1 (high)
		x64Q4KScalesMins(w, "R9", q4Kx8ScalesOff+24*sb)
		w("\tVMOVQ\tR13, X6")
		w("\tVMOVQ\tR10, X7")
		x64Q4KScalesMins(w, "R9", q4Kx8ScalesOff+24*sb+12)
		w("\tVMOVQ\tR13, X12")
		w("\tVMOVQ\tR10, X15")
		w("\tVPSHUFB\tX10, X6, X6")    // scales lo, hadd order
		w("\tVPSHUFB\tX10, X12, X12")  // scales hi
		w("\tVPSHUFB\tX10, X7, X7")    // mins lo
		w("\tVPSHUFB\tX10, X15, X15")  // mins hi
		w("\tVPUNPCKLBW\tX15, X7, X7") // [m_lo(c), m_hi(c)] pairs, hadd column order
		w("\tVPMOVZXBW\tX7, Y7")       // 16 x i16
		w("\tVPMOVZXBD\tX6, Y6")       // 8 x i32 scales lo
		w("\tVPMOVZXBD\tX12, Y12")     // scales hi
		// bias += pairs . (bsum_lo, bsum_hi) of this chunk
		w("\tVPBROADCASTD\t%d(SP), Y15", 4*sb)
		w("\tVPMADDWD\tY15, Y7, Y7")
		w("\tVPADDD\tY7, Y5, Y5")
		// dots: four quads; lo/hi nibbles; columns 0-3 (Y2) and 4-7 (Y3)
		for nib := 0; nib < 2; nib++ {
			w("\tVPXOR\tY2, Y2, Y2")
			w("\tVPXOR\tY3, Y3, Y3")
			for k := 0; k < 4; k++ {
				var aoff int
				if gemm {
					aoff = q8Kx4QsOff + 32*(8*sb+4*nib+k) + 8*row
				} else {
					aoff = 4 + 64*sb + 32*nib + 8*k
				}
				w("\tVPBROADCASTQ\t%d(DX), Y15", aoff)
				for half := 0; half < 2; half++ {
					w("\tVMOVDQU\t%d(R9), Y7", q4Kx8QsOff+256*sb+64*k+32*half)
					if nib == 0 {
						w("\tVPAND\tY8, Y7, Y7")
					} else {
						w("\tVPSRLW\t$4, Y7, Y7")
						w("\tVPAND\tY8, Y7, Y7")
					}
					w("\tVPMADDUBSW\tY15, Y7, Y7")
					w("\tVPADDW\tY7, Y%d, Y%d", 2+half, 2+half)
				}
			}
			w("\tVPMADDWD\tY9, Y2, Y2")
			w("\tVPMADDWD\tY9, Y3, Y3")
			w("\tVPHADDD\tY3, Y2, Y2") // [c0 c1 c4 c5 | c2 c3 c6 c7]
			if nib == 0 {
				w("\tVPMULLD\tY6, Y2, Y2")
			} else {
				w("\tVPMULLD\tY12, Y2, Y2")
			}
			w("\tVPADDD\tY2, Y4, Y4")
		}
	}
	w("\tVCVTDQ2PS\tY4, Y4")
	w("\tVFMADD231PS\tY13, Y4, Y0")
	w("\tVCVTDQ2PS\tY5, Y5")
	w("\tVFMADD231PS\tY14, Y5, Y1")
	w("\tADDQ\t$%d, R9", q4Kx8BlockBytes)
	w("\tADDQ\t$%d, DX", actBlock)
	w("\tDECQ\tR8")
	w("\tJNZ\t%sblk", lbl)
	w("\tVSUBPS\tY1, Y0, Y0")
	w("\tVPERMPS\tY0, Y11, Y0")
	w("\tVMOVUPS\tY0, (DI)")
}

func x64Q4KPrologue(w func(string, ...any), wide bool, gemm bool, oob string) {
	argOff, _ := repackGemmArgs(wide)
	movArg := "MOVL"
	if wide {
		movArg = "MOVQ"
	}
	w("\tMOVLQSX\tl0+8(FP), CX")
	w("\tSHRQ\t$8, CX") // nb
	w("\tMOVLQZX\tl6+%d(FP), R11", argOff["l6"])
	w("\tSHRQ\t$3, R11") // column groups
	w("\t%s\tl1+%d(FP), DI", movArg, argOff["l1"])
	w("\t%s\tl3+%d(FP), SI", movArg, argOff["l3"])
	w("\t%s\tl4+%d(FP), DX", movArg, argOff["l4"])
	if gemm {
		w("\tMOVLQZX\tl5+%d(FP), R12", argOff["l5"])
		w("\tSHRQ\t$2, R12") // row groups
		w("\t%s\tl2+%d(FP), R13", movArg, argOff["l2"])
		w("\tSHLQ\t$2, R13") // bs bytes
		// s + (nr-1)*bs*4 + nc*4
		w("\tLEAQ\t(R12*4), AX")
		w("\tDECQ\tAX")
		w("\tIMULQ\tR13, AX")
		w("\tLEAQ\t(DI)(AX*1), AX")
		w("\tLEAQ\t(AX)(R11*8), AX")
		w("\tLEAQ\t(AX)(R11*8), AX")
		w("\tLEAQ\t(AX)(R11*8), AX")
		w("\tLEAQ\t(AX)(R11*8), AX")
		w("\tCMPQ\tR15, AX")
		w("\tJCS\t%s", oob)
		w("\tIMUL3Q\t$%d, CX, AX", q8Kx4BlockBytes)
		w("\tIMULQ\tR12, AX")
		w("\tADDQ\tDX, AX")
		w("\tCMPQ\tR15, AX")
		w("\tJCS\t%s", oob)
	} else {
		w("\tLEAQ\t(DI)(R11*8), AX")
		w("\tLEAQ\t(AX)(R11*8), AX")
		w("\tLEAQ\t(AX)(R11*8), AX")
		w("\tLEAQ\t(AX)(R11*8), AX") // s + nc*4
		w("\tCMPQ\tR15, AX")
		w("\tJCS\t%s", oob)
		w("\tIMUL3Q\t$%d, CX, AX", q8_KBlockBytes)
		w("\tADDQ\tDX, AX")
		w("\tCMPQ\tR15, AX")
		w("\tJCS\t%s", oob)
	}
	w("\tIMUL3Q\t$%d, CX, AX", q4Kx8BlockBytes) // group stride
	w("\tMOVQ\tAX, R10")
	w("\tIMULQ\tR11, AX")
	w("\tADDQ\tSI, AX")
	w("\tCMPQ\tR15, AX")
	w("\tJCS\t%s", oob)
	w("\tADDQ\tR14, DI")
	w("\tADDQ\tR14, SI")
	w("\tADDQ\tR14, DX")
}

// x64GemvQ4K8x8Kernel emits the AVX2 GEMV under sym.
func x64GemvQ4K8x8Kernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	w := func(format string, args ...any) { fmt.Fprintf(&sb, format+"\n", args...) }
	cSym := pool.addBlob(x64Q4KConsts())
	w("// %s: q4_K 8x8 repack GEMV (AVX2).", sym)
	x64Q4KPrologue(w, wide, false, "gkoob")
	w("\tTESTQ\tR11, R11")
	w("\tJZ\tgkdone")
	w("\tTESTQ\tCX, CX")
	w("\tJZ\tgkdone") // nb == 0: nothing to write
	w("\tVMOVDQU\t·%s+%d(SB), Y8", cSym, x64q4kLow)
	w("\tVMOVDQU\t·%s+%d(SB), Y9", cSym, x64q4kOnes)
	w("\tVMOVDQU\t·%s+%d(SB), X10", cSym, x64q4kShuf)
	w("\tVMOVDQU\t·%s+%d(SB), Y11", cSym, x64q4kPerm)
	w("\tMOVQ\tDX, 24(SP)")  // activation row
	w("\tMOVQ\tR11, 40(SP)") // groups left
	w("\tMOVQ\tR10, 64(SP)") // group stride
	w("gkgroup:")
	w("\tMOVQ\t24(SP), DX")
	x64Q4K8x8Body(w, "gk", false, 0)
	w("\tADDQ\t$32, DI")
	w("\tADDQ\t64(SP), SI")
	w("\tDECQ\t40(SP)")
	w("\tJNZ\tgkgroup")
	w("gkdone:")
	w("\tVZEROUPPER")
	w("\tRET")
	w("gkoob:")
	w("\tVZEROUPPER")
	w("\tJMP\tovr_oob")
	return sb.String()
}

// x64Q4KGemmTile emits the block loop of one (row group, column group)
// tile: the four block_q8_Kx4 rows share every weight load, nibble
// unpack and scale decode. Y0..Y3 the rows' i16 pair sums of the current
// (nibble, column half), Y6/Y12 the sub-block scales (low/high nibbles,
// i32, hadd order), Y5 the mins pairs, Y7 weights, Y8 0x0f, Y9 i16 ones,
// X10 shuffle, Y11 permute, Y13/Y4 the block's d/dmin column scales,
// Y14/Y15 scratch. On entry: SI = weight group, DX = activation row
// group, CX = nb. The row accumulators live on the frame (see
// x64Q4KTileFrame).
func x64Q4KGemmTile(w func(string, ...any)) {
	w("\tVXORPS\tY0, Y0, Y0")
	for r := 0; r < 4; r++ {
		w("\tVMOVUPS\tY0, %d(SP)", 448+32*r) // f32 accumulators
	}
	w("\tMOVQ\tCX, R8")
	w("\tMOVQ\tSI, R9")
	w("gtblk:")
	// block-sum pairs of the eight sub-blocks per row -> frame [0..64)
	for r := 0; r < 4; r++ {
		for q := 0; q < 4; q++ {
			w("\tMOVWLSX\t%d(DX), AX", q8Kx4BsumsOff+32*q+8*r)
			w("\tMOVWLSX\t%d(DX), BX", q8Kx4BsumsOff+32*q+8*r+2)
			w("\tADDL\tBX, AX")
			w("\tMOVW\tAX, %d(SP)", 16*r+4*q)
			w("\tMOVWLSX\t%d(DX), AX", q8Kx4BsumsOff+32*q+8*r+4)
			w("\tMOVWLSX\t%d(DX), BX", q8Kx4BsumsOff+32*q+8*r+6)
			w("\tADDL\tBX, AX")
			w("\tMOVW\tAX, %d(SP)", 16*r+4*q+2)
		}
	}
	w("\tVPXOR\tY0, Y0, Y0")
	for r := 0; r < 4; r++ {
		w("\tVMOVDQU\tY0, %d(SP)", 192+32*r) // sumi
		w("\tVMOVDQU\tY0, %d(SP)", 320+32*r) // bias
	}
	for sb := 0; sb < 4; sb++ {
		// scales/mins of sub-blocks 2sb (low nibbles) and 2sb+1 (high)
		x64Q4KScalesMins(w, "R9", q4Kx8ScalesOff+24*sb)
		w("\tVMOVQ\tR13, X6")
		w("\tVMOVQ\tR10, X7")
		x64Q4KScalesMins(w, "R9", q4Kx8ScalesOff+24*sb+12)
		w("\tVMOVQ\tR13, X12")
		w("\tVMOVQ\tR10, X15")
		w("\tVPSHUFB\tX10, X6, X6")
		w("\tVPSHUFB\tX10, X12, X12")
		w("\tVPSHUFB\tX10, X7, X7")
		w("\tVPSHUFB\tX10, X15, X15")
		w("\tVPUNPCKLBW\tX15, X7, X7")
		w("\tVPMOVZXBW\tX7, Y5") // mins pairs, 16 x i16
		w("\tVPMOVZXBD\tX6, Y6")
		w("\tVPMOVZXBD\tX12, Y12")
		// bias[r] += pairs . (bsum_lo, bsum_hi) of this chunk
		for r := 0; r < 4; r++ {
			w("\tVPBROADCASTD\t%d(SP), Y15", 16*r+4*sb)
			w("\tVPMADDWD\tY15, Y5, Y15")
			w("\tVPADDD\t%d(SP), Y15, Y15", 320+32*r)
			w("\tVMOVDQU\tY15, %d(SP)", 320+32*r)
		}
		for nib := 0; nib < 2; nib++ {
			for half := 0; half < 2; half++ {
				for r := 0; r < 4; r++ {
					w("\tVPXOR\tY%d, Y%d, Y%d", r, r, r)
				}
				for k := 0; k < 4; k++ {
					w("\tVMOVDQU\t%d(R9), Y7", q4Kx8QsOff+256*sb+64*k+32*half)
					if nib == 0 {
						w("\tVPAND\tY8, Y7, Y7")
					} else {
						w("\tVPSRLW\t$4, Y7, Y7")
						w("\tVPAND\tY8, Y7, Y7")
					}
					for r := 0; r < 4; r++ {
						w("\tVPBROADCASTQ\t%d(DX), Y15", q8Kx4QsOff+32*(8*sb+4*nib+k)+8*r)
						w("\tVPMADDUBSW\tY15, Y7, Y14")
						w("\tVPADDW\tY14, Y%d, Y%d", r, r)
					}
				}
				for r := 0; r < 4; r++ {
					w("\tVPMADDWD\tY9, Y%d, Y%d", r, r)
					if half == 0 {
						w("\tVMOVDQU\tY%d, %d(SP)", r, 64+32*r)
						continue
					}
					w("\tVMOVDQU\t%d(SP), Y14", 64+32*r)
					w("\tVPHADDD\tY%d, Y14, Y14", r) // [c0 c1 c4 c5 | c2 c3 c6 c7]
					if nib == 0 {
						w("\tVPMULLD\tY6, Y14, Y14")
					} else {
						w("\tVPMULLD\tY12, Y14, Y14")
					}
					w("\tVPADDD\t%d(SP), Y14, Y14", 192+32*r)
					w("\tVMOVDQU\tY14, %d(SP)", 192+32*r)
				}
			}
		}
	}
	// fold: f32[r] += sumi[r] * d * yd[r] - bias[r] * dmin * yd[r] (hadd order)
	w("\tVCVTPH2PS\t(R9), Y13")
	w("\tVPERMPS\tY13, Y11, Y13")
	w("\tVCVTPH2PS\t16(R9), Y4")
	w("\tVPERMPS\tY4, Y11, Y4")
	for r := 0; r < 4; r++ {
		w("\tVBROADCASTSS\t%d(DX), Y15", 4*r)
		w("\tVMULPS\tY15, Y13, Y14")
		w("\tVMULPS\tY15, Y4, Y15")
		w("\tVCVTDQ2PS\t%d(SP), Y0", 192+32*r)
		w("\tVCVTDQ2PS\t%d(SP), Y1", 320+32*r)
		w("\tVMOVUPS\t%d(SP), Y2", 448+32*r)
		w("\tVFMADD231PS\tY14, Y0, Y2")
		w("\tVFNMADD231PS\tY15, Y1, Y2")
		w("\tVMOVUPS\tY2, %d(SP)", 448+32*r)
	}
	w("\tADDQ\t$%d, R9", q4Kx8BlockBytes)
	w("\tADDQ\t$%d, DX", q8Kx4BlockBytes)
	w("\tDECQ\tR8")
	w("\tJNZ\tgtblk")
}

// x64GemmQ4K8x8Kernel emits the AVX2 GEMM under sym: one tile of four
// activation rows per (row group, column group), the weight decode
// shared by the rows (see x64Q4KGemmTile).
func x64GemmQ4K8x8Kernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	w := func(format string, args ...any) { fmt.Fprintf(&sb, format+"\n", args...) }
	cSym := pool.addBlob(x64Q4KConsts())
	w("// %s: q4_K 8x8 repack GEMM (AVX2), four activation rows per weight decode.", sym)
	x64Q4KPrologue(w, wide, true, "gmoob")
	w("\tTESTQ\tR11, R11")
	w("\tJZ\tgmdone")
	w("\tTESTQ\tR12, R12")
	w("\tJZ\tgmdone")
	w("\tTESTQ\tCX, CX")
	w("\tJZ\tgmdone")
	w("\tVMOVDQU\t·%s+%d(SB), Y8", cSym, x64q4kLow)
	w("\tVMOVDQU\t·%s+%d(SB), Y9", cSym, x64q4kOnes)
	w("\tVMOVDQU\t·%s+%d(SB), X10", cSym, x64q4kShuf)
	w("\tVMOVDQU\t·%s+%d(SB), Y11", cSym, x64q4kPerm)
	w("\tMOVQ\tSI, 576(SP)")  // vx
	w("\tMOVQ\tDX, 584(SP)")  // activation base of the row group
	w("\tMOVQ\tDI, 592(SP)")  // tile output base
	w("\tMOVQ\tR11, 600(SP)") // column groups
	w("\tMOVQ\tR12, 608(SP)") // row groups left
	w("\tMOVQ\tR13, 616(SP)") // bs bytes
	w("\tMOVQ\tR10, 624(SP)") // group stride
	// the scale decoder clobbers R10..R13 and BX: every loop count lives
	// on the frame, 632 being the column groups left in this row group.
	w("gmrows:")
	w("\tMOVQ\t576(SP), SI")
	w("\tMOVQ\t600(SP), AX")
	w("\tMOVQ\tAX, 632(SP)")
	w("gmcols:")
	w("\tMOVQ\t584(SP), DX")
	x64Q4KGemmTile(w)
	// store the four rows (hadd order -> column order)
	w("\tMOVQ\t592(SP), DI")
	for r := 0; r < 4; r++ {
		w("\tVMOVUPS\t%d(SP), Y0", 448+32*r)
		w("\tVPERMPS\tY0, Y11, Y0")
		w("\tVMOVUPS\tY0, (DI)")
		if r < 3 {
			w("\tADDQ\t616(SP), DI")
		}
	}
	w("\tADDQ\t$32, 592(SP)")
	w("\tADDQ\t624(SP), SI")
	w("\tDECQ\t632(SP)")
	w("\tJNZ\tgmcols")
	// next row group: activations advance nb blocks; the tile base moves
	// back by the columns written and down four rows.
	w("\tIMUL3Q\t$%d, CX, AX", q8Kx4BlockBytes)
	w("\tADDQ\tAX, 584(SP)")
	w("\tMOVQ\t600(SP), AX")
	w("\tSHLQ\t$5, AX") // groups * 32 bytes
	w("\tSUBQ\tAX, 592(SP)")
	w("\tMOVQ\t616(SP), AX")
	w("\tSHLQ\t$2, AX") // 4 rows
	w("\tADDQ\tAX, 592(SP)")
	w("\tDECQ\t608(SP)")
	w("\tJNZ\tgmrows")
	w("gmdone:")
	w("\tVZEROUPPER")
	w("\tRET")
	w("gmoob:")
	w("\tVZEROUPPER")
	w("\tJMP\tovr_oob")
	return sb.String()
}
