package asm

import (
	"encoding/binary"
	"fmt"
	"strings"
)

// AVX2 bodies of the Q5_0 8x8 repack GEMV and GEMM (layouts in
// repack_q5_0_a64.go). A 32-byte load m' (m' = 0..3) of qs holds four
// columns (4m' % 8 ..) times eight elements: low nibbles are elements
// 8(m'/2).., high nibbles 16 later; qh[8m'..8m'+8) carry the fifth bits
// of its eight (column, half) runs as [lo c0, lo c1, hi c0, hi c1, lo
// c2, lo c3, hi c2, hi c3]. VPMADDUBSW multiplies the unsigned quants
// (0..31) with the signed activations, VPMADDWD folds to i32 lanes
// [c0 c0 c1 c1 | c2 c2 c3 c3], VPHADDD of the two column halves gives
// [c0 c1 c4 c5 | c2 c3 c6 c7] (the "hadd order", undone by one VPERMPS
// at the store), and the -16 offset is 16 x the activation block sum.
// The GEMM keeps the four rows' i32 tiles in registers and its f32
// tiles in the frame. FastMath only.

// x64Q5Consts: 0: 32 x 0x0f; 32: 32 x 0x10; 64: bit mask 1,2,..,128 x4;
// 96: VPSHUFB index, low-nibble runs; 128: high-nibble runs; 160: 16 x
// i16 1; 192: 32 x u8 1; 224: VPERMPS index [0 1 4 5 2 3 6 7].
func x64Q5Consts() []byte {
	c := make([]byte, 416)
	for i := 0; i < 32; i++ {
		c[288+i] = 0x88 // q4_0x8 nibble xor
	}
	for i := 0; i < 32; i++ {
		c[256+i] = byte(kvaluesIQ4NL[i%16]) // iq4_nl table, signed
		c[320+i] = byte(kvaluesFP4[i%16])   // mxfp4 table, signed
	}
	for i := 0; i < 8; i++ {
		binary.LittleEndian.PutUint32(c[352+4*i:], 1)          // i32 ones (E8M0 decode)
		binary.LittleEndian.PutUint32(c[384+4*i:], 0x00200000) // E8M0 denormal base
	}
	for i := 0; i < 32; i++ {
		c[i] = 0x0f
		c[32+i] = 0x10
		c[64+i] = 1 << (i % 8)
		c[96+i] = []byte{0, 1, 4, 5}[i/8]
		c[128+i] = []byte{2, 3, 6, 7}[i/8]
		c[192+i] = 1
	}
	for i := 0; i < 16; i++ {
		c[160+2*i] = 1
	}
	for i, v := range []byte{0, 1, 4, 5, 2, 3, 6, 7} {
		c[224+4*i] = v
	}
	return c
}

const (
	x64q5Low    = 0
	x64q5High   = 32
	x64q5Bits   = 64
	x64q5IdxLo  = 96
	x64q5IdxHi  = 128
	x64q5Ones16 = 160
	x64q5Ones8  = 192
	x64q5LUT    = 256
	x64q5Xor    = 288
	x64q5FP4    = 320
	x64q5One32  = 352
	x64q5Denorm = 384
	x64q5Perm   = 224
	// GEMM frame: 0 the rows' 16 x block sums in hadd-order lanes (row 0
	// at 0, 1 at 4, 2 at 16, 3 at 20) | 32 f32 tiles (4 x 32) | 160 vx |
	// 168 output row-group base.
	x64GemmQ5Frame = 176
)

// x64Q5Unpack loads weight run m' of the block at R9 into Y<lo> (low-
// nibble elements) and Y<hi> (high-nibble elements), 32 unsigned bytes
// each, through Y<raw> (also the bit scratch) and Y<qh>. c is the
// constant blob symbol.
func x64Q5Unpack(w func(string, ...any), c string, m, raw, lo, hi, qh int) {
	x64X8Unpack(w, c, m, raw, lo, hi, qh, q5_0x8L)
}

// x64X8Unpack is x64Q5Unpack for any x8Layout (no fifth bits for q4_0).
func x64X8Unpack(w func(string, ...any), c string, m, raw, lo, hi, qh int, L x8Layout) {
	w("\tVMOVDQU\t%d(R9), Y%d", L.qsOff+32*m, raw)
	if L.xor != 0 {
		w("\tVPXOR\t%s+%d(SB), Y%d, Y%d", c, x64q5Xor, raw, raw) // undo the repack's nibble ^ 8
	}
	w("\tVPAND\t%s+%d(SB), Y%d, Y%d", c, x64q5Low, raw, lo)
	w("\tVPSRLW\t$4, Y%d, Y%d", raw, hi)
	w("\tVPAND\t%s+%d(SB), Y%d, Y%d", c, x64q5Low, hi, hi)
	if L.lut {
		// Signed kvalues through the (free) qh register. The multiply
		// then uses the abs/sign idiom: VPMADDUBSW saturates its i16 pair
		// sums, and an unsigned table (kvalues + 127, up to 240) against
		// s8 activations overflows them; |kvalues| <= 127 keeps every pair
		// sum within range.
		tbl := x64q5LUT
		if L.e8m0 {
			tbl = x64q5FP4
		}
		w("\tVMOVDQU\t%s+%d(SB), Y%d", c, tbl, qh)
		w("\tVPSHUFB\tY%d, Y%d, Y%d", lo, qh, lo)
		w("\tVPSHUFB\tY%d, Y%d, Y%d", hi, qh, hi)
	}
	if !L.fifth {
		return
	}
	w("\tVPBROADCASTQ\t%d(R9), Y%d", L.qhOff+8*m, qh)
	for _, h := range []struct{ idx, dst int }{{x64q5IdxLo, lo}, {x64q5IdxHi, hi}} {
		w("\tVPSHUFB\t%s+%d(SB), Y%d, Y%d", c, h.idx, qh, raw)
		w("\tVPAND\t%s+%d(SB), Y%d, Y%d", c, x64q5Bits, raw, raw)
		w("\tVPCMPEQB\t%s+%d(SB), Y%d, Y%d", c, x64q5Bits, raw, raw)
		w("\tVPAND\t%s+%d(SB), Y%d, Y%d", c, x64q5High, raw, raw)
		w("\tVPOR\tY%d, Y%d, Y%d", raw, h.dst, h.dst)
	}
}

// x64Q5Prologue loads the arguments, checks bounds and translates the
// pointers: CX nb, DI s, R9 vx, R10 vy, R11 column groups, R12 group
// stride (weights), BX row groups (GEMM) / unused, R13 bs bytes (GEMM).
func x64Q5Prologue(w func(string, ...any), wide, gemm bool, oob string) {
	x64X8Prologue(w, wide, gemm, oob, q5_0x8L)
}

func x64X8Prologue(w func(string, ...any), wide, gemm bool, oob string, L x8Layout) {
	argOff, _ := repackGemmArgs(wide)
	movPtr := "MOVL"
	if wide {
		movPtr = "MOVQ"
	}
	w("\tMOVL\tl0+8(FP), CX")
	w("\tSHRL\t$5, CX") // nb
	w("\tMOVL\tl6+%d(FP), R11", argOff["l6"])
	w("\tSHRL\t$3, R11") // column groups
	w("\t%s\tl1+%d(FP), DI", movPtr, argOff["l1"])
	w("\t%s\tl3+%d(FP), R9", movPtr, argOff["l3"])
	w("\t%s\tl4+%d(FP), R10", movPtr, argOff["l4"])
	w("\tIMUL3Q\t$%d, CX, R12", L.blockBytes) // group stride
	if gemm {
		w("\tMOVL\tl5+%d(FP), BX", argOff["l5"])
		w("\tSHRL\t$2, BX") // row groups
		w("\t%s\tl2+%d(FP), R13", movPtr, argOff["l2"])
		w("\tSHLQ\t$2, R13") // bs bytes
		w("\tTESTQ\tBX, BX")
		w("\tJZ\tdone%s", L.lbl)
	}
	w("\tTESTQ\tR11, R11")
	w("\tJZ\tdone%s", L.lbl)
	// s + (nr-1)*bs*4 + nc*4
	if gemm {
		w("\tLEAQ\t-1(BX*4), AX")
		w("\tIMULQ\tR13, AX")
		w("\tADDQ\tDI, AX")
	} else {
		w("\tMOVQ\tDI, AX")
	}
	w("\tLEAQ\t(AX)(R11*8), AX")
	w("\tLEAQ\t(AX)(R11*8), AX")
	w("\tLEAQ\t(AX)(R11*8), AX")
	w("\tLEAQ\t(AX)(R11*8), AX")
	w("\tCMPQ\tR15, AX")
	w("\tJCS\t%s", oob)
	w("\tMOVQ\tR12, AX")
	w("\tIMULQ\tR11, AX")
	w("\tADDQ\tR9, AX")
	w("\tCMPQ\tR15, AX")
	w("\tJCS\t%s", oob)
	if gemm {
		w("\tIMUL3Q\t$%d, CX, AX", q8_0x4BlockBytes)
		w("\tIMULQ\tBX, AX")
	} else {
		w("\tIMUL3Q\t$%d, CX, AX", q8_0BlockBytes)
	}
	w("\tADDQ\tR10, AX")
	w("\tCMPQ\tR15, AX")
	w("\tJCS\t%s", oob)
	w("\tADDQ\tR14, DI")
	w("\tADDQ\tR14, R9")
	w("\tADDQ\tR14, R10")
}

// x64GemvQ5_0_8x8Kernel emits the GEMV (nr == 1) under sym.
//
// Registers: CX nb, DI s (advancing), SI weight block, DX activation
// block, R8 blocks left, R9 weight group, R10 activation row, R11 groups
// left, R12 group stride. Y0/Y1 i32 column halves, Y2 f32 sums (hadd
// order), Y11 16 x block sum, Y13 u8 ones, Y15 the permute index,
// Y4..Y10, Y12, Y14 scratch.
func x64GemvQ5_0_8x8Kernel(sym string, pool *ConstPool, wide bool) string {
	return x64GemvX8Kernel(sym, pool, wide, q5_0x8L)
}

// x64GemvQ4_0_8x8Kernel emits the q4_0 8x8 GEMV (q5_0 body, no fifth
// bits, -8 through the block sum).
func x64GemvQ4_0_8x8Kernel(sym string, pool *ConstPool, wide bool) string {
	return x64GemvX8Kernel(sym, pool, wide, q4_0x8L)
}

// x64GemvIQ4NL8x8Kernel / x64GemmIQ4NL8x8Kernel: the iq4_nl 8x8 bodies (the
// q4_0 bodies with signed kvalues looked up per nibble and the abs/sign
// pair dot in place of the unsigned unpack's folded offset).
func x64GemvIQ4NL8x8Kernel(sym string, pool *ConstPool, wide bool) string {
	return x64GemvX8Kernel(sym, pool, wide, iq4_nlx8L)
}

func x64GemmIQ4NL8x8Kernel(sym string, pool *ConstPool, wide bool) string {
	return x64GemmX8Kernel(sym, pool, wide, iq4_nlx8L)
}

// x64X8Scales leaves the block's eight column scales as f32 in Y<dst>:
// the f16 row widened, or for E8M0 blocks ggml_e8m0_to_fp32_half of each
// byte (2^(e-128): (e-1) << 23 for e >= 2, the denormal 0x00200000 << e
// below), using three scratch registers.
func x64X8Scales(w func(string, ...any), c string, L x8Layout, dst, t0, t1, t2 int) {
	if !L.e8m0 {
		w("\tVCVTPH2PS\t(R9), Y%d", dst)
		return
	}
	w("\tVPMOVZXBD\t(R9), Y%d", dst)
	w("\tVPSUBD\t%s+%d(SB), Y%d, Y%d", c, x64q5One32, dst, t0)
	w("\tVPSLLD\t$23, Y%d, Y%d", t0, t0) // (e-1) << 23
	w("\tVMOVDQU\t%s+%d(SB), Y%d", c, x64q5Denorm, t1)
	w("\tVPSLLVD\tY%d, Y%d, Y%d", dst, t1, t1)                   // 0x00200000 << e
	w("\tVPCMPGTD\t%s+%d(SB), Y%d, Y%d", c, x64q5One32, dst, t2) // e > 1
	w("\tVBLENDVPS\tY%d, Y%d, Y%d, Y%d", t2, t0, t1, dst)
}

// x64GemvMXFP4_8x8Kernel / x64GemmMXFP4_8x8Kernel: the iq4_nl x8 bodies
// with the fp4 table and E8M0 column scales.
func x64GemvMXFP4_8x8Kernel(sym string, pool *ConstPool, wide bool) string {
	return x64GemvX8Kernel(sym, pool, wide, mxfp4x8L)
}

func x64GemmMXFP4_8x8Kernel(sym string, pool *ConstPool, wide bool) string {
	return x64GemmX8Kernel(sym, pool, wide, mxfp4x8L)
}

func x64GemvX8Kernel(sym string, pool *ConstPool, wide bool, L x8Layout) string {
	var sb strings.Builder
	w := func(format string, args ...any) { fmt.Fprintf(&sb, format+"\n", args...) }
	c := "·" + pool.addBlob(x64Q5Consts())
	if L.lut {
		w("// %s: %s 8x8 repack GEMV (AVX2), abs/sign VPMADDUBSW over the signed table lookups.", sym, L.name)
	} else {
		w("// %s: %s 8x8 repack GEMV (AVX2), VPMADDUBSW over the unpacked runs; -%d folded through the block sum.", sym, L.name, x8Offset(L))
	}
	x64X8Prologue(w, wide, false, "oob"+L.lbl, L)
	w("\tVMOVDQU\t%s+%d(SB), Y13", c, x64q5Ones8)
	w("\tVMOVDQU\t%s+%d(SB), Y15", c, x64q5Perm)
	w("group%s:", L.lbl)
	w("\tVXORPS\tY2, Y2, Y2")
	w("\tMOVQ\tR10, DX")
	w("\tMOVQ\tCX, R8")
	w("\tTESTQ\tR8, R8")
	w("\tJZ\tstore%s", L.lbl)
	w("blk%s:", L.lbl)
	if !L.lut {
		// 2^shift x block sum of the activations in every lane of Y11: the
		// quant offset the unsigned unpack carries.
		w("\tVMOVDQU\t2(DX), Y10")
		w("\tVPMADDUBSW\tY10, Y13, Y10")
		w("\tVPMADDWD\t%s+%d(SB), Y10, Y10", c, x64q5Ones16)
		w("\tVEXTRACTI128\t$1, Y10, X11")
		w("\tVPADDD\tX11, X10, X10")
		w("\tVPHADDD\tX10, X10, X10")
		w("\tVPHADDD\tX10, X10, X10")
		w("\tVPSLLD\t$%d, X10, X10", L.shift)
		w("\tVPBROADCASTD\tX10, Y11")
	}
	w("\tVPXOR\tY0, Y0, Y0")
	w("\tVPXOR\tY1, Y1, Y1")
	for m := 0; m < 4; m++ {
		x64X8Unpack(w, c, m, 4, 5, 6, 12, L)
		base := 8 * (m / 2)
		acc := m % 2
		w("\tVPBROADCASTQ\t%d(DX), Y8", 2+base)
		w("\tVPBROADCASTQ\t%d(DX), Y9", 2+base+16)
		if L.lut {
			// signed table: |w| x sign(y, w)
			w("\tVPSIGNB\tY5, Y8, Y10")
			w("\tVPSIGNB\tY5, Y5, Y5")
			w("\tVPMADDUBSW\tY10, Y5, Y10")
		} else {
			w("\tVPMADDUBSW\tY8, Y5, Y10")
		}
		w("\tVPMADDWD\t%s+%d(SB), Y10, Y10", c, x64q5Ones16)
		w("\tVPADDD\tY10, Y%d, Y%d", acc, acc)
		if L.lut {
			w("\tVPSIGNB\tY6, Y9, Y10")
			w("\tVPSIGNB\tY6, Y6, Y6")
			w("\tVPMADDUBSW\tY10, Y6, Y10")
		} else {
			w("\tVPMADDUBSW\tY9, Y6, Y10")
		}
		w("\tVPMADDWD\t%s+%d(SB), Y10, Y10", c, x64q5Ones16)
		w("\tVPADDD\tY10, Y%d, Y%d", acc, acc)
	}
	w("\tVPHADDD\tY1, Y0, Y0") // [c0 c1 c4 c5 | c2 c3 c6 c7]
	if !L.lut {
		w("\tVPSUBD\tY11, Y0, Y0")
	}
	w("\tVCVTDQ2PS\tY0, Y0")
	x64X8Scales(w, c, L, 14, 4, 5, 6)
	w("\tVPERMPS\tY14, Y15, Y14")
	w("\tMOVWLZX\t(DX), AX")
	w("\tVMOVD\tAX, X10")
	w("\tVCVTPH2PS\tX10, X10")
	w("\tVBROADCASTSS\tX10, Y10")
	w("\tVMULPS\tY10, Y14, Y14")
	w("\tVFMADD231PS\tY14, Y0, Y2")
	w("\tADDQ\t$%d, R9", L.blockBytes)
	w("\tADDQ\t$%d, DX", q8_0BlockBytes)
	w("\tDECQ\tR8")
	w("\tJNZ\tblk%s", L.lbl)
	w("store%s:", L.lbl)
	w("\tVPERMPS\tY2, Y15, Y2")
	w("\tVMOVUPS\tY2, (DI)")
	w("\tADDQ\t$32, DI")
	w("\tDECQ\tR11")
	w("\tJNZ\tgroup%s", L.lbl)
	w("done%s:", L.lbl)
	w("\tVZEROUPPER")
	w("\tRET")
	w("oob%s:", L.lbl)
	w("\tVZEROUPPER")
	w("\tJMP\tovr_oob")
	return sb.String()
}

// x64GemmQ5_0_8x8Kernel emits the GEMM (nr % 4 == 0) under sym: the
// four activation rows of a block_q8_0x4 share every unpacked run.
//
// Registers: CX nb, SI weight group, R9 weight block, R10 activation
// group, DX activation block, R8 blocks left, DI output for the column
// group, R11 column groups left, R12 group stride, R13 bs bytes, BX row
// groups left. Y(2m), Y(2m+1) the i32 column halves of row m, Y8..Y11
// unpack (Y9 low, Y10 high), Y12 the activation run, Y13 scratch,
// Y14/Y15 epilogue scratch.
func x64GemmQ5_0_8x8Kernel(sym string, pool *ConstPool, wide bool) string {
	return x64GemmX8Kernel(sym, pool, wide, q5_0x8L)
}

// x64GemmQ4_0_8x8Kernel emits the q4_0 8x8 GEMM (q5_0 tile, no fifth
// bits, -8 through the block sums).
func x64GemmQ4_0_8x8Kernel(sym string, pool *ConstPool, wide bool) string {
	return x64GemmX8Kernel(sym, pool, wide, q4_0x8L)
}

func x64GemmX8Kernel(sym string, pool *ConstPool, wide bool, L x8Layout) string {
	var sb strings.Builder
	w := func(format string, args ...any) { fmt.Fprintf(&sb, format+"\n", args...) }
	c := "·" + pool.addBlob(x64Q5Consts())
	sumOff := [4]int{0, 4, 16, 20}
	w("// %s: %s 8x8 repack GEMM (AVX2), four activation rows per unpacked run; -%d folded through the block sums.", sym, L.name, x8Offset(L))
	x64X8Prologue(w, wide, true, "oob"+L.lbl, L)
	w("\tMOVQ\tR9, 160(SP)")  // vx
	w("\tMOVQ\tDI, 168(SP)")  // output row-group base
	w("\tMOVQ\tR11, 176(SP)") // column groups
	w("rows%s:", L.lbl)
	w("\tMOVQ\t160(SP), SI")
	w("\tMOVQ\t168(SP), DI")
	w("\tMOVQ\t176(SP), R11")
	w("cols%s:", L.lbl)
	w("\tVXORPS\tY0, Y0, Y0")
	for i := 0; i < 4; i++ {
		w("\tVMOVUPS\tY0, %d(SP)", 32+32*i)
	}
	w("\tMOVQ\tSI, R9")
	w("\tMOVQ\tR10, DX")
	w("\tMOVQ\tCX, R8")
	w("\tTESTQ\tR8, R8")
	w("\tJZ\tstore%s", L.lbl)
	w("blk%s:", L.lbl)
	// 16 x block sums of the four rows: the block's four 32-byte runs are
	// [r0 8B | r1 8B | r2 8B | r3 8B]; pair-sum each with VPMADDUBSW
	// against u8 ones, add the runs, fold to i32 and to per-row lanes.
	w("\tVMOVDQU\t%s+%d(SB), Y13", c, x64q5Ones8)
	for k := 0; k < 4; k++ {
		w("\tVMOVDQU\t%d(DX), Y%d", q8_0x4QsOff+32*k, 8+k)
		w("\tVPMADDUBSW\tY%d, Y13, Y%d", 8+k, 8+k)
	}
	w("\tVPADDW\tY9, Y8, Y8")
	w("\tVPADDW\tY11, Y10, Y10")
	w("\tVPADDW\tY10, Y8, Y8")
	w("\tVPMADDWD\t%s+%d(SB), Y8, Y8", c, x64q5Ones16) // [r0 r0 r1 r1 | r2 r2 r3 r3]
	w("\tVPHADDD\tY8, Y8, Y8")                         // [r0 r1 r0 r1 | r2 r3 r2 r3]
	if L.lut {
		w("\tVPXOR\tY8, Y8, Y8") // signed table: no quant offset to fold
	} else {
		w("\tVPSLLD\t$%d, Y8, Y8", L.shift)
	}
	w("\tVMOVDQU\tY8, 0(SP)")
	for i := 0; i < 8; i++ {
		w("\tVPXOR\tY%d, Y%d, Y%d", i, i, i)
	}
	for m := 0; m < 4; m++ {
		x64X8Unpack(w, c, m, 8, 9, 10, 11, L)
		if L.lut {
			// signed table: |w| in Y11 (lo) / Y8 (hi), both free after the
			// unpack; each activation broadcast is signed by w before the
			// u8 x s8 pair dot.
			w("\tVPSIGNB\tY9, Y9, Y11")
			w("\tVPSIGNB\tY10, Y10, Y8")
		}
		h := m % 2
		klo, khi := m/2, 2+m/2
		for r := 0; r < 4; r++ {
			acc := 2*r + h
			w("\tVPBROADCASTQ\t%d(DX), Y12", q8_0x4QsOff+32*klo+8*r)
			if L.lut {
				w("\tVPSIGNB\tY9, Y12, Y13")
				w("\tVPMADDUBSW\tY13, Y11, Y13")
			} else {
				w("\tVPMADDUBSW\tY12, Y9, Y13")
			}
			w("\tVPMADDWD\t%s+%d(SB), Y13, Y13", c, x64q5Ones16)
			w("\tVPADDD\tY13, Y%d, Y%d", acc, acc)
			w("\tVPBROADCASTQ\t%d(DX), Y12", q8_0x4QsOff+32*khi+8*r)
			if L.lut {
				w("\tVPSIGNB\tY10, Y12, Y13")
				w("\tVPMADDUBSW\tY13, Y8, Y13")
			} else {
				w("\tVPMADDUBSW\tY12, Y10, Y13")
			}
			w("\tVPMADDWD\t%s+%d(SB), Y13, Y13", c, x64q5Ones16)
			w("\tVPADDD\tY13, Y%d, Y%d", acc, acc)
		}
	}
	// epilogue: column scales in hadd order (Y15), then per row
	w("\tVMOVDQU\t%s+%d(SB), Y13", c, x64q5Perm)
	x64X8Scales(w, c, L, 15, 8, 9, 14)
	w("\tVPERMPS\tY15, Y13, Y15")
	for r := 0; r < 4; r++ {
		w("\tVPHADDD\tY%d, Y%d, Y14", 2*r+1, 2*r) // [c0 c1 c4 c5 | c2 c3 c6 c7]
		w("\tVPBROADCASTD\t%d(SP), Y8", sumOff[r])
		w("\tVPSUBD\tY8, Y14, Y14")
		w("\tVCVTDQ2PS\tY14, Y14")
		w("\tMOVWLZX\t%d(DX), AX", 2*r)
		w("\tVMOVD\tAX, X8")
		w("\tVCVTPH2PS\tX8, X8")
		w("\tVBROADCASTSS\tX8, Y8")
		w("\tVMULPS\tY8, Y15, Y8")
		w("\tVMOVUPS\t%d(SP), Y9", 32+32*r)
		w("\tVFMADD231PS\tY8, Y14, Y9")
		w("\tVMOVUPS\tY9, %d(SP)", 32+32*r)
	}
	w("\tADDQ\t$%d, R9", L.blockBytes)
	w("\tADDQ\t$%d, DX", q8_0x4BlockBytes)
	w("\tDECQ\tR8")
	w("\tJNZ\tblk%s", L.lbl)
	w("store%s:", L.lbl)
	w("\tVMOVDQU\t%s+%d(SB), Y13", c, x64q5Perm)
	w("\tMOVQ\tDI, AX")
	for r := 0; r < 4; r++ {
		w("\tVMOVUPS\t%d(SP), Y8", 32+32*r)
		w("\tVPERMPS\tY8, Y13, Y8")
		w("\tVMOVUPS\tY8, (AX)")
		if r < 3 {
			w("\tADDQ\tR13, AX")
		}
	}
	w("\tADDQ\t$32, DI")
	w("\tADDQ\tR12, SI")
	w("\tDECQ\tR11")
	w("\tJNZ\tcols%s", L.lbl)
	// next row group: activations advance by nb blocks, outputs by 4 rows
	w("\tIMUL3Q\t$%d, CX, AX", q8_0x4BlockBytes)
	w("\tADDQ\tAX, R10")
	w("\tLEAQ\t(R13)(R13*2), AX")
	w("\tADDQ\tR13, AX")
	w("\tADDQ\tAX, 168(SP)")
	w("\tDECQ\tBX")
	w("\tJNZ\trows%s", L.lbl)
	w("done%s:", L.lbl)
	w("\tVZEROUPPER")
	w("\tRET")
	w("oob%s:", L.lbl)
	w("\tVZEROUPPER")
	w("\tJMP\tovr_oob")
	return sb.String()
}

// x8Offset is the quant offset the AVX2 bodies fold through the block
// sums: 2^shift for the unsigned unpacks, none for the signed iq4_nl
// table (its bodies use the abs/sign idiom instead).
func x8Offset(L x8Layout) int {
	if L.lut {
		return 0
	}
	return 1 << L.shift
}
