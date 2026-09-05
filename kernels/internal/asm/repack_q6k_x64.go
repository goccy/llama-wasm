package asm

import (
	"fmt"
	"strings"
)

// amd64 (AVX2) body of the Q6_K 8x8 repack GEMV. One activation row:
// per 16-quant sub-block the two 8-byte activation quads are broadcast
// to every 64-bit lane, the 6-bit quants of four columns are rebuilt
// unsigned from their ql nibbles and qh bit pairs (32 bytes = 8 quants
// of each of four columns), VPMADDUBSW yields four i16 pair sums per
// column (at most 32004 after the sub-block's two quads), VPMADDWD
// folds to i32, VPHADDD folds the two column halves into eight lanes in
// the order [c0 c1 c4 c5 c2 c3 c6 c7], the i8 sub-block scales apply as
// i32 lane multiplies, and the -32 offset is the scales' dot with the
// activation block sums, subtracted once per super-block. Accumulates in
// f32 per super-block and is permuted back to column order at the store.
// FastMath only.
//
// Layouts: see repack_q6k_a64.go. Constants: x64Q6KConsts (the Q4_K
// blob plus the qh masks); the AVX2 encodings take them as memory
// operands so the registers stay with the data.

// x64Q6KConsts:
//
//	  0: 32 x 0x0f
//	 32: 16 x i16 1
//	 64: VPSHUFB index (xmm): scale bytes [s0..s7] -> [s0 s1 s4 s5 s2 s3 s6 s7] then zero
//	 80: VPERMPS index: [0 1 4 5 2 3 6 7] -> column order
//	112: 32 x 0x03
//	144: 32 x 0x30
func x64Q6KConsts() []byte {
	c := append(x64Q4KConsts(), make([]byte, 64)...)
	for i := 0; i < 32; i++ {
		c[112+i] = 0x03
		c[144+i] = 0x30
	}
	return c
}

const (
	x64q6kLo2 = 112
	x64q6kHi2 = 144
	// frame: 0 bsum scratch (4) | 16 vx | 24 activation base | 32 tile
	// output base | 40 column groups left | 48 row groups left | 56 bs
	// bytes | 64 group stride.
	x64Q6KFrame = 80
	// tiled GEMM frame: 0 half-0 i32 partials (4 x 32) | 128 sumi
	// accumulators (4 x 32) | 256 bias accumulators (4 x 32) | 384 f32
	// accumulators (4 x 32) | 512 vx | 520 activation base | 528 tile
	// output | 536 column groups | 544 row groups left | 552 bs bytes |
	// 560 group stride | 568 column groups left.
	x64Q6KTileFrame = 576
)

// x64Q6K8x8Body emits the per-column-group body. On entry: SI = weight
// group, DX = activation block (advancing per block), CX = nb, DI =
// output for the eight columns. Y11 = permute index (loaded by the
// caller); cSym the constants. Clobbers Y0..Y10, Y12..Y15, AX, R8, R9.
func x64Q6K8x8Body(w func(string, ...any), lbl, cSym string) {
	w("\tVXORPS\tY0, Y0, Y0") // f32 sum
	w("\tMOVQ\tCX, R8")
	w("\tMOVQ\tSI, R9")
	w("%sblk:", lbl)
	w("\tVPXOR\tY8, Y8, Y8") // sumi (i32, hadd order)
	w("\tVPXOR\tY9, Y9, Y9") // bias (i32, hadd order)
	for half := 0; half < 2; half++ {
		for sbk := 0; sbk < 4; sbk++ {
			for i := 2; i < 6; i++ {
				w("\tVPXOR\tY%d, Y%d, Y%d", i, i, i)
			}
			aoff := 4 + 128*half + 16*sbk
			qlBase := q6Kx8QlOff + 512*half + 128*sbk
			qhBase := q6Kx8QhOff + 256*half + 128*(sbk&1)
			for k := 0; k < 2; k++ {
				w("\tVPBROADCASTQ\t%d(DX), Y15", aoff+8*k)    // low quants of the 16
				w("\tVPBROADCASTQ\t%d(DX), Y14", aoff+64+8*k) // high quants
				for ch := 0; ch < 2; ch++ {
					w("\tVMOVDQU\t%d(R9), Y10", qlBase+64*k+32*ch)
					w("\tVMOVDQU\t%d(R9), Y12", qhBase+64*k+32*ch)
					if sbk >= 2 {
						w("\tVPSRLW\t$2, Y12, Y12")
					}
					// low: (ql & 0x0f) | (qh & 0x03) << 4
					w("\tVPAND\t·%s+%d(SB), Y10, Y13", cSym, x64q4kLow)
					w("\tVPAND\t·%s+%d(SB), Y12, Y7", cSym, x64q6kLo2)
					w("\tVPSLLW\t$4, Y7, Y7")
					w("\tVPOR\tY7, Y13, Y13")
					w("\tVPMADDUBSW\tY15, Y13, Y13")
					w("\tVPADDW\tY13, Y%d, Y%d", 2+ch, 2+ch)
					// high: (ql >> 4) | (qh & 0x30)
					w("\tVPSRLW\t$4, Y10, Y10")
					w("\tVPAND\t·%s+%d(SB), Y10, Y10", cSym, x64q4kLow)
					w("\tVPAND\t·%s+%d(SB), Y12, Y12", cSym, x64q6kHi2)
					w("\tVPOR\tY12, Y10, Y10")
					w("\tVPMADDUBSW\tY14, Y10, Y10")
					w("\tVPADDW\tY10, Y%d, Y%d", 4+ch, 4+ch)
				}
			}
			for i := 2; i < 6; i++ {
				w("\tVPMADDWD\t·%s+%d(SB), Y%d, Y%d", cSym, x64q4kOnes, i, i)
			}
			w("\tVPHADDD\tY3, Y2, Y2") // low quants, [c0 c1 c4 c5 | c2 c3 c6 c7]
			w("\tVPHADDD\tY5, Y4, Y4") // high quants
			// sub-block scales j = 8h + sb (low) and j + 4 (high), hadd order, i32
			jl := 8*half + sbk
			w("\tVMOVQ\t%d(R9), X6", q6Kx8ScalesOff+8*jl)
			w("\tVPSHUFB\t·%s+%d(SB), X6, X6", cSym, x64q4kShuf)
			w("\tVPMOVSXBD\tX6, Y6")
			w("\tVMOVQ\t%d(R9), X7", q6Kx8ScalesOff+8*(jl+4))
			w("\tVPSHUFB\t·%s+%d(SB), X7, X7", cSym, x64q4kShuf)
			w("\tVPMOVSXBD\tX7, Y7")
			w("\tVPMULLD\tY6, Y2, Y2")
			w("\tVPADDD\tY2, Y8, Y8")
			w("\tVPMULLD\tY7, Y4, Y4")
			w("\tVPADDD\tY4, Y8, Y8")
			// bias += scales . block sums of the two sub-blocks
			w("\tMOVWLSX\t%d(DX), AX", 260+2*jl)
			w("\tVMOVD\tAX, X13")
			w("\tVPBROADCASTD\tX13, Y13")
			w("\tVPMULLD\tY13, Y6, Y6")
			w("\tVPADDD\tY6, Y9, Y9")
			w("\tMOVWLSX\t%d(DX), AX", 260+2*(jl+4))
			w("\tVMOVD\tAX, X13")
			w("\tVPBROADCASTD\tX13, Y13")
			w("\tVPMULLD\tY13, Y7, Y7")
			w("\tVPADDD\tY7, Y9, Y9")
		}
	}
	// sumi -= 32 * bias; f32 += sumi * d * yd (hadd order)
	w("\tVPSLLD\t$5, Y9, Y9")
	w("\tVPSUBD\tY9, Y8, Y8")
	w("\tVCVTDQ2PS\tY8, Y8")
	w("\tVBROADCASTSS\t(DX), Y1")
	w("\tVCVTPH2PS\t(R9), Y13")
	w("\tVPERMPS\tY13, Y11, Y13")
	w("\tVMULPS\tY1, Y13, Y13")
	w("\tVFMADD231PS\tY13, Y8, Y0")
	w("\tADDQ\t$%d, R9", q6Kx8BlockBytes)
	w("\tADDQ\t$%d, DX", q8_KBlockBytes)
	w("\tDECQ\tR8")
	w("\tJNZ\t%sblk", lbl)
	w("\tVPERMPS\tY0, Y11, Y0")
	w("\tVMOVUPS\tY0, (DI)")
}

// x64GemvQ6K8x8Kernel emits the AVX2 GEMV under sym.
func x64GemvQ6K8x8Kernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	w := func(format string, args ...any) { fmt.Fprintf(&sb, format+"\n", args...) }
	cSym := pool.addBlob(x64Q6KConsts())
	w("// %s: q6_K 8x8 repack GEMV (AVX2).", sym)
	x64RepackPrologue(w, wide, false, "g6oob", q6Kx8BlockBytes)
	w("\tTESTQ\tR11, R11")
	w("\tJZ\tg6done")
	w("\tTESTQ\tCX, CX")
	w("\tJZ\tg6done") // nb == 0: nothing to write
	w("\tVMOVDQU\t·%s+%d(SB), Y11", cSym, x64q4kPerm)
	w("\tMOVQ\tDX, 24(SP)")  // activation row
	w("\tMOVQ\tR11, 40(SP)") // groups left
	w("\tMOVQ\tR10, 64(SP)") // group stride
	w("g6group:")
	w("\tMOVQ\t24(SP), DX")
	x64Q6K8x8Body(w, "g6", cSym)
	w("\tADDQ\t$32, DI")
	w("\tADDQ\t64(SP), SI")
	w("\tDECQ\t40(SP)")
	w("\tJNZ\tg6group")
	w("g6done:")
	w("\tVZEROUPPER")
	w("\tRET")
	w("g6oob:")
	w("\tVZEROUPPER")
	w("\tJMP\tovr_oob")
	return sb.String()
}

// x64Q6KGemmTile emits the block loop of one (row group, column group)
// tile: the four block_q8_Kx4 rows share every weight load and 6-bit
// unpack. Y0..Y3 the rows' i16 pair sums of the current (low/high,
// column half), Y6/Y12 the sub-block scales (low/high quants, i32, hadd
// order), Y7 the unpacked weights, Y10/Y4 the ql/qh bytes, Y11 the
// permute index, Y13..Y15 scratch. On entry: SI = weight group, DX =
// activation row group, CX = nb. The row accumulators live on the frame
// (see x64Q6KTileFrame).
func x64Q6KGemmTile(w func(string, ...any), cSym string) {
	w("\tVXORPS\tY0, Y0, Y0")
	for r := 0; r < 4; r++ {
		w("\tVMOVUPS\tY0, %d(SP)", 384+32*r) // f32 accumulators
	}
	w("\tMOVQ\tCX, R8")
	w("\tMOVQ\tSI, R9")
	w("m6blk:")
	w("\tVPXOR\tY0, Y0, Y0")
	for r := 0; r < 4; r++ {
		w("\tVMOVDQU\tY0, %d(SP)", 128+32*r) // sumi
		w("\tVMOVDQU\tY0, %d(SP)", 256+32*r) // bias
	}
	for half := 0; half < 2; half++ {
		for sbk := 0; sbk < 4; sbk++ {
			jl := 8*half + sbk
			qlBase := q6Kx8QlOff + 512*half + 128*sbk
			qhBase := q6Kx8QhOff + 256*half + 128*(sbk&1)
			// sub-block scales j (low quants) -> Y6, j + 4 (high) -> Y12, hadd order
			w("\tVMOVQ\t%d(R9), X6", q6Kx8ScalesOff+8*jl)
			w("\tVPSHUFB\t·%s+%d(SB), X6, X6", cSym, x64q4kShuf)
			w("\tVPMOVSXBD\tX6, Y6")
			w("\tVMOVQ\t%d(R9), X12", q6Kx8ScalesOff+8*(jl+4))
			w("\tVPSHUFB\t·%s+%d(SB), X12, X12", cSym, x64q4kShuf)
			w("\tVPMOVSXBD\tX12, Y12")
			// bias[r] += scales . block sums of the two sub-blocks (quarter-major bsums)
			for r := 0; r < 4; r++ {
				for _, j := range []int{jl, jl + 4} {
					sc := "Y6"
					if j != jl {
						sc = "Y12"
					}
					w("\tMOVWLSX\t%d(DX), AX", q8Kx4BsumsOff+2*(16*(j/4)+4*r+j%4))
					w("\tVMOVD\tAX, X13")
					w("\tVPBROADCASTD\tX13, Y13")
					w("\tVPMULLD\t%s, Y13, Y13", sc)
					w("\tVPADDD\t%d(SP), Y13, Y13", 256+32*r)
					w("\tVMOVDQU\tY13, %d(SP)", 256+32*r)
				}
			}
			for lohi := 0; lohi < 2; lohi++ {
				for ch := 0; ch < 2; ch++ {
					for r := 0; r < 4; r++ {
						w("\tVPXOR\tY%d, Y%d, Y%d", r, r, r)
					}
					for k := 0; k < 2; k++ {
						w("\tVMOVDQU\t%d(R9), Y10", qlBase+64*k+32*ch)
						w("\tVMOVDQU\t%d(R9), Y4", qhBase+64*k+32*ch)
						if sbk >= 2 {
							w("\tVPSRLW\t$2, Y4, Y4")
						}
						if lohi == 0 {
							// low: (ql & 0x0f) | (qh & 0x03) << 4
							w("\tVPAND\t·%s+%d(SB), Y10, Y7", cSym, x64q4kLow)
							w("\tVPAND\t·%s+%d(SB), Y4, Y4", cSym, x64q6kLo2)
							w("\tVPSLLW\t$4, Y4, Y4")
							w("\tVPOR\tY4, Y7, Y7")
						} else {
							// high: (ql >> 4) | (qh & 0x30)
							w("\tVPSRLW\t$4, Y10, Y7")
							w("\tVPAND\t·%s+%d(SB), Y7, Y7", cSym, x64q4kLow)
							w("\tVPAND\t·%s+%d(SB), Y4, Y4", cSym, x64q6kHi2)
							w("\tVPOR\tY4, Y7, Y7")
						}
						// quarter index of this row's 8 quants
						qi := 16*half + 2*sbk + k + 8*lohi
						for r := 0; r < 4; r++ {
							w("\tVPBROADCASTQ\t%d(DX), Y15", q8Kx4QsOff+32*qi+8*r)
							w("\tVPMADDUBSW\tY15, Y7, Y14")
							w("\tVPADDW\tY14, Y%d, Y%d", r, r)
						}
					}
					for r := 0; r < 4; r++ {
						w("\tVPMADDWD\t·%s+%d(SB), Y%d, Y%d", cSym, x64q4kOnes, r, r)
						if ch == 0 {
							w("\tVMOVDQU\tY%d, %d(SP)", r, 32*r)
							continue
						}
						w("\tVMOVDQU\t%d(SP), Y14", 32*r)
						w("\tVPHADDD\tY%d, Y14, Y14", r) // [c0 c1 c4 c5 | c2 c3 c6 c7]
						if lohi == 0 {
							w("\tVPMULLD\tY6, Y14, Y14")
						} else {
							w("\tVPMULLD\tY12, Y14, Y14")
						}
						w("\tVPADDD\t%d(SP), Y14, Y14", 128+32*r)
						w("\tVMOVDQU\tY14, %d(SP)", 128+32*r)
					}
				}
			}
		}
	}
	// fold: f32[r] += (sumi[r] - 32 * bias[r]) * d * yd[r] (hadd order)
	w("\tVCVTPH2PS\t(R9), Y13")
	w("\tVPERMPS\tY13, Y11, Y13")
	for r := 0; r < 4; r++ {
		w("\tVBROADCASTSS\t%d(DX), Y15", 4*r)
		w("\tVMULPS\tY15, Y13, Y14")
		w("\tVMOVDQU\t%d(SP), Y1", 256+32*r)
		w("\tVPSLLD\t$5, Y1, Y1")
		w("\tVMOVDQU\t%d(SP), Y0", 128+32*r)
		w("\tVPSUBD\tY1, Y0, Y0")
		w("\tVCVTDQ2PS\tY0, Y0")
		w("\tVMOVUPS\t%d(SP), Y2", 384+32*r)
		w("\tVFMADD231PS\tY14, Y0, Y2")
		w("\tVMOVUPS\tY2, %d(SP)", 384+32*r)
	}
	w("\tADDQ\t$%d, R9", q6Kx8BlockBytes)
	w("\tADDQ\t$%d, DX", q8Kx4BlockBytes)
	w("\tDECQ\tR8")
	w("\tJNZ\tm6blk")
}

// x64GemmQ6K8x8Kernel emits the AVX2 GEMM under sym: one tile of four
// activation rows per (row group, column group), the weight unpack
// shared by the rows (see x64Q6KGemmTile).
func x64GemmQ6K8x8Kernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	w := func(format string, args ...any) { fmt.Fprintf(&sb, format+"\n", args...) }
	cSym := pool.addBlob(x64Q6KConsts())
	w("// %s: q6_K 8x8 repack GEMM (AVX2), four activation rows per weight unpack.", sym)
	x64RepackPrologue(w, wide, true, "m6oob", q6Kx8BlockBytes)
	w("\tTESTQ\tR11, R11")
	w("\tJZ\tm6done")
	w("\tTESTQ\tR12, R12")
	w("\tJZ\tm6done")
	w("\tTESTQ\tCX, CX")
	w("\tJZ\tm6done")
	w("\tVMOVDQU\t·%s+%d(SB), Y11", cSym, x64q4kPerm)
	w("\tMOVQ\tSI, 512(SP)")  // vx
	w("\tMOVQ\tDX, 520(SP)")  // activation base of the row group
	w("\tMOVQ\tDI, 528(SP)")  // tile output base
	w("\tMOVQ\tR11, 536(SP)") // column groups
	w("\tMOVQ\tR12, 544(SP)") // row groups left
	w("\tMOVQ\tR13, 552(SP)") // bs bytes
	w("\tMOVQ\tR10, 560(SP)") // group stride
	w("m6rows:")
	w("\tMOVQ\t512(SP), SI")
	w("\tMOVQ\t536(SP), AX")
	w("\tMOVQ\tAX, 568(SP)")
	w("m6cols:")
	w("\tMOVQ\t520(SP), DX")
	x64Q6KGemmTile(w, cSym)
	// store the four rows (hadd order -> column order)
	w("\tMOVQ\t528(SP), DI")
	for r := 0; r < 4; r++ {
		w("\tVMOVUPS\t%d(SP), Y0", 384+32*r)
		w("\tVPERMPS\tY0, Y11, Y0")
		w("\tVMOVUPS\tY0, (DI)")
		if r < 3 {
			w("\tADDQ\t552(SP), DI")
		}
	}
	w("\tADDQ\t$32, 528(SP)")
	w("\tADDQ\t560(SP), SI")
	w("\tDECQ\t568(SP)")
	w("\tJNZ\tm6cols")
	// next row group: activations advance nb blocks; the tile base moves
	// back by the columns written and down four rows.
	w("\tIMUL3Q\t$%d, CX, AX", q8Kx4BlockBytes)
	w("\tADDQ\tAX, 520(SP)")
	w("\tMOVQ\t536(SP), AX")
	w("\tSHLQ\t$5, AX") // groups * 32 bytes
	w("\tSUBQ\tAX, 528(SP)")
	w("\tMOVQ\t552(SP), AX")
	w("\tSHLQ\t$2, AX") // 4 rows
	w("\tADDQ\tAX, 528(SP)")
	w("\tDECQ\t544(SP)")
	w("\tJNZ\tm6rows")
	w("m6done:")
	w("\tVZEROUPPER")
	w("\tRET")
	w("m6oob:")
	w("\tVZEROUPPER")
	w("\tJMP\tovr_oob")
	return sb.String()
}
