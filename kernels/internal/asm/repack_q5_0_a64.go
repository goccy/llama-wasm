package asm

import (
	"fmt"
	"strings"
)

// Q5_0 8x8 repack GEMV/GEMM (ggml_gemv/gemm_q5_0_8x8_q8_0, exported by
// llama-wasm as dbg_gemv_q5_0_8x8 / dbg_gemm_q5_0_8x8): eight Q5_0 rows
// interleaved as block_q5_0x8 against q8_0 activations (one plain
// block_q8_0 row for the GEMV, block_q8_0x4 groups of four rows for the
// GEMM). The quants are unpacked unsigned (nibble | fifth bit << 4,
// 0..31, positive as int8) and the -16 offset is applied through the
// activation block sums, so SDOT/SMMLA run on the raw unpacked bytes.
// FastMath only.
//
// block_q5_0x8 (176 bytes): d[8] f16 (0) | qh[32] (16) | qs[128] (48).
// The 16-byte load m of qs (m = 0..7) holds columns 2(m%4), 2(m%4)+1:
// its low nibbles are elements 8(m/4)..+8, its high nibbles elements
// 16 later; qh[4m..4m+4) are the fifth bits of those four (column,
// half) runs, one byte each (bit t = element t of the run).
//
// block_q8_0 (34 bytes): d f16 (0) | qs[32] (2). block_q8_0x4 (136
// bytes): d[4] f16 (0) | qs[128] (8) with qs[32k + 8m + i] = row m,
// element 8k + i.

// x8Layout describes a legacy-quant block repacked eight rows wide:
// block_q5_0x8 (176) = d[8] | qh[32] | qs[128], block_q4_0x8 (144) = d[8]
// | qs[128] (llama.cpp's block<4, 8>). The unsigned quants are offset by
// 2^shift (16 for q5_0, 8 for q4_0), applied through the block sums.
type x8Layout struct {
	name       string
	lbl        string // label suffix
	blockBytes int
	qsOff      int
	qhOff      int
	shift      int  // log2 of the quant offset
	fifth      bool // qh carries a fifth bit
	lut        bool // iq4_nl: nibbles index the kvalues table (signed bytes)
	noBias     bool // iq4_nl on arm64: signed quants, no offset term
	xor        int  // q4_0: llama.cpp's make_block_q4_0x8 stores nibble ^ 8 (0x88 per byte); undo it
}

var (
	q5_0x8L = x8Layout{name: "q5_0", lbl: "5", blockBytes: 176, qsOff: 48, qhOff: 16, shift: 4, fifth: true}
	q4_0x8L = x8Layout{name: "q4_0", lbl: "4", blockBytes: 144, qsOff: 16, shift: 3, xor: 0x88}
	// iq4_nl: block<4, 8> like q4_0 (144 bytes); the nibbles are indices
	// into kvalues_iq4nl. arm64 dots the signed table values directly; the
	// AVX2 bodies use the table + 127 (unsigned) and fold 127 x the block
	// sums back out.
	iq4_nlx8L = x8Layout{name: "iq4_nl", lbl: "i", blockBytes: 144, qsOff: 16, lut: true, noBias: true}
)

// kvaluesIQ4NL is llama.cpp's kvalues_iq4nl.
var kvaluesIQ4NL = [16]int8{-127, -104, -83, -65, -49, -35, -22, -10, 1, 13, 25, 38, 53, 69, 89, 113}

const (
	q5_0x8BlockBytes = 176
	q5_0x8QhOff      = 16
	q5_0x8QsOff      = 48
	q8_0x4BlockBytes = 136
	q8_0x4QsOff      = 8
	// GEMM frame: the f32 4x8 tile as eight SMMLA-shaped quads.
	a64GemmQ5Scratch = 128
	a64GemmQ5Frame   = 144
)

// q5x8Consts: 0: SDOT bit mask (1,2,..,128 twice); 16: TBL index for the
// low-nibble fifth bits (byte 0 x8, byte 1 x8); 32: for the high-nibble
// ones (byte 2 x8, byte 3 x8); 48: kvalues_iq4nl (signed).
func q5x8Consts() []byte {
	c := make([]byte, 64)
	for i := 0; i < 16; i++ {
		c[i] = 1 << (i % 8)
		c[16+i] = byte(i / 8)
		c[32+i] = byte(2 + i/8)
		c[48+i] = byte(kvaluesIQ4NL[i])
	}
	return c
}

const q5x8LUTOff = 48

// a64Q5 adds the encodings the Q5_0 repack bodies need on top of a64Q.
type a64Q5 struct{ *a64Q }

func (e *a64Q5) dup4s0(d, n int) {
	e.word(0x4E040400|uint32(n)<<5|uint32(d), fmt.Sprintf("dup v%d.4s, v%d.s[0]", d, n))
}

// loadConsts puts the pool blob into v29 (bit mask), v28 (low index),
// v27 (high index) and builds v31 = 0x0f, v30 = 0x10, v26 = 1 bytes.
func (e *a64Q5) loadConsts(sym string) {
	e.w("\tMOVD\t$·%s(SB), R12", sym)
	e.ldurQ(29, 12, 0)
	e.ldurQ(28, 12, 16)
	e.ldurQ(27, 12, 32)
	e.movi16(31, 0x0f)
	e.movi16(30, 0x10)
	e.movi16(26, 1)
}

// unpack loads weight run m of the block at R9 into v9 (low-nibble
// elements) and v10 (high-nibble elements), 16 unsigned bytes each
// [column 2(m%4) x8 | column 2(m%4)+1 x8], through v8, v11 and tmp.
func (e *a64Q5) unpack(m, tmp int) { e.unpackL(m, tmp, q5_0x8L) }

// unpackL is unpack for any x8Layout (no fifth bits for q4_0).
func (e *a64Q5) unpackL(m, tmp int, L x8Layout) {
	e.ldurQ(8, 9, L.qsOff+16*m)
	if L.xor != 0 {
		e.movi16(tmp, L.xor) // the repack stores nibble ^ 8: back to the unsigned nibble
		e.eor16(8, 8, tmp)
	}
	e.and16(9, 8, 31)
	e.ushr16(10, 8, 4)
	if L.lut {
		e.tbl16(9, 25, 9) // table v25 = kvalues (loaded by the kernel), indices the nibbles
		e.tbl16(10, 25, 10)
	}
	if !L.fifth {
		return
	}
	e.ldurS(11, 9, L.qhOff+4*m)
	e.tbl16(tmp, 11, 28)
	e.cmtst16(tmp, tmp, 29)
	e.and16(tmp, tmp, 30)
	e.orr16(9, 9, tmp)
	e.tbl16(tmp, 11, 27)
	e.cmtst16(tmp, tmp, 29)
	e.and16(tmp, tmp, 30)
	e.orr16(10, 10, tmp)
}

// a64GemvQ5_0_8x8Kernel emits the GEMV (nr == 1) under sym.
//
// Registers: R1 nb, R2 s, R3 weight group, R4 activation row, R6 group
// stride, R7 groups left, R9 weight block, R10 activation block, R11
// blocks left. v0..v3 the i32 column-pair accumulators, v4/v5 the f32
// sums, v13/v14 activation runs, v15..v17 scales, v20..v22 the block
// sum, v24 unpack scratch, v26..v31 constants.
func a64GemvQ5_0_8x8Kernel(sym string, pool *ConstPool, wide bool) string {
	return a64GemvX8Kernel(sym, pool, wide, q5_0x8L)
}

// a64GemvQ4_0_8x8Kernel emits the q4_0 8x8 GEMV: the q5_0 body without
// the fifth bits, -8 folded through the block sum.
func a64GemvQ4_0_8x8Kernel(sym string, pool *ConstPool, wide bool) string {
	return a64GemvX8Kernel(sym, pool, wide, q4_0x8L)
}

func a64GemvX8Kernel(sym string, pool *ConstPool, wide bool, L x8Layout) string {
	var sb strings.Builder
	e := &a64Q5{newA64Q(&sb)}
	w := e.w
	cSym := pool.addBlob(q5x8Consts())
	argOff, _ := repackGemmArgs(wide)
	movArg := "MOVWU"
	if wide {
		movArg = "MOVD"
	}
	w("// %s: %s 8x8 repack GEMV, SDOT over the unpacked runs; -%d folded through the block sum.", sym, L.name, 1<<L.shift)
	w("\tMOVW\tl0+8(FP), R1")
	w("\tLSRW\t$5, R1, R1") // nb
	w("\tMOVWU\tl6+%d(FP), R7", argOff["l6"])
	w("\tLSRW\t$3, R7, R7") // column groups
	w("\tCBZW\tR7, gv%sdone", L.lbl)
	w("\t%s\tl1+%d(FP), R2", movArg, argOff["l1"])
	w("\tADD\tR7<<5, R2, R27")
	w("\tCMP\tR27, R21")
	w("\tBLO\tgv%soob", L.lbl)
	w("\t%s\tl3+%d(FP), R3", movArg, argOff["l3"])
	w("\tMOVD\t$%d, R6", L.blockBytes)
	w("\tMUL\tR1, R6, R6") // group stride
	w("\tMUL\tR7, R6, R27")
	w("\tADD\tR3, R27, R27")
	w("\tCMP\tR27, R21")
	w("\tBLO\tgv%soob", L.lbl)
	w("\t%s\tl4+%d(FP), R4", movArg, argOff["l4"])
	w("\tMOVD\t$%d, R27", q8_0BlockBytes)
	w("\tMUL\tR1, R27, R27")
	w("\tADD\tR4, R27, R27")
	w("\tCMP\tR27, R21")
	w("\tBLO\tgv%soob", L.lbl)
	w("\tADD\tR20, R2, R2")
	w("\tADD\tR20, R3, R3")
	w("\tADD\tR20, R4, R4")
	e.loadConsts(cSym)
	if L.lut {
		w("\tMOVD\t$·%s(SB), R12", cSym)
		e.ldurQ(25, 12, q5x8LUTOff)
	}
	w("gv%sgroup:", L.lbl)
	e.movi4s0(4)
	e.movi4s0(5)
	w("\tMOVD\tR3, R9")
	w("\tMOVD\tR4, R10")
	w("\tMOVW\tR1, R11")
	w("\tCBZW\tR11, gv%sstore", L.lbl)
	w("gv%sblk:", L.lbl)
	// block sum of the activations, times the quant offset, in every lane of v22
	if !L.noBias {
		e.ldurQ(20, 10, 2)
		e.ldurQ(21, 10, 18)
		e.movi4s0(22)
		e.sdot(22, 20, 26)
		e.sdot(22, 21, 26)
		e.addv4s(22, 22)
		e.shl4s(22, 22, L.shift)
		e.dup4s0(22, 22)
	}
	for i := 0; i < 4; i++ {
		e.movi4s0(i)
	}
	for m := 0; m < 8; m++ {
		e.unpackL(m, 24, L)
		base := 8 * (m / 4)
		e.ldurD(13, 10, 2+base)
		e.dup2d(13, 13, 0)
		e.ldurD(14, 10, 2+base+16)
		e.dup2d(14, 14, 0)
		e.sdot(m%4, 9, 13)
		e.sdot(m%4, 10, 14)
	}
	e.addp4s(0, 0, 1) // columns 0..3
	e.addp4s(1, 2, 3) // columns 4..7
	if !L.noBias {
		e.sub4s(0, 0, 22)
		e.sub4s(1, 1, 22)
	}
	e.scvtf4s(0, 0)
	e.scvtf4s(1, 1)
	e.ldurD(15, 9, 0)
	e.fcvtl(15, 15)
	e.ldurD(16, 9, 8)
	e.fcvtl(16, 16)
	e.ldurH(17, 10, 0)
	e.fcvtSH(17, 17)
	e.fmulLane(15, 15, 17, 0)
	e.fmulLane(16, 16, 17, 0)
	e.fmla4s(4, 0, 15)
	e.fmla4s(5, 1, 16)
	w("\tADD\t$%d, R9, R9", L.blockBytes)
	w("\tADD\t$%d, R10, R10", q8_0BlockBytes)
	w("\tSUBW\t$1, R11, R11")
	w("\tCBNZW\tR11, gv%sblk", L.lbl)
	w("gv%sstore:", L.lbl)
	e.sturQ(4, 2, 0)
	e.sturQ(5, 2, 16)
	w("\tADD\t$32, R2, R2")
	w("\tADD\tR3, R6, R3")
	w("\tSUBW\t$1, R7, R7")
	w("\tCBNZW\tR7, gv%sgroup", L.lbl)
	w("gv%sdone:", L.lbl)
	w("\tRET")
	w("gv%soob:", L.lbl)
	w("\tB\tovr_oob")
	return sb.String()
}

// a64GemmQ5_0_8x8Kernel emits the GEMM (nr % 4 == 0) under sym: SMMLA
// 2x2 tiles of (column pair, row pair) over the unpacked runs.
//
// Registers: R1 nb, R2 output row-group base, R3 vx, R4 activation
// row group, R5 bs bytes, R6 group stride, R7 column groups, R8 row
// groups left, R0 weight group, R24 output for the column group, R25
// column groups left, R9/R10 block pointers, R11 blocks left, R23
// scratch. v0..v7 i32 tiles (cp + 4rp), v8..v11 unpack, v12..v19 the
// block's activation runs, v20..v25 sums/bias/scale scratch, v26..v31
// constants.
func a64GemmQ5_0_8x8Kernel(sym string, pool *ConstPool, wide bool) string {
	return a64GemmX8Kernel(sym, pool, wide, q5_0x8L)
}

// a64GemmQ4_0_8x8Kernel emits the q4_0 8x8 GEMM (the q5_0 tile without
// the fifth bits, -8 folded through the block sums).
func a64GemmQ4_0_8x8Kernel(sym string, pool *ConstPool, wide bool) string {
	return a64GemmX8Kernel(sym, pool, wide, q4_0x8L)
}

// a64GemvIQ4NL8x8Kernel / a64GemmIQ4NL8x8Kernel emit the iq4_nl 8x8 bodies:
// the q4_0 bodies with the nibbles looked up in kvalues_iq4nl (TBL), which
// are signed, so no offset term.
func a64GemvIQ4NL8x8Kernel(sym string, pool *ConstPool, wide bool) string {
	return a64GemvX8Kernel(sym, pool, wide, iq4_nlx8L)
}

func a64GemmIQ4NL8x8Kernel(sym string, pool *ConstPool, wide bool) string {
	return a64GemmX8Kernel(sym, pool, wide, iq4_nlx8L)
}

func a64GemmX8Kernel(sym string, pool *ConstPool, wide bool, L x8Layout) string {
	var sb strings.Builder
	e := &a64Q5{newA64Q(&sb)}
	w := e.w
	cSym := pool.addBlob(q5x8Consts())
	argOff, _ := repackGemmArgs(wide)
	movArg := "MOVWU"
	if wide {
		movArg = "MOVD"
	}
	acc := func(cp, rp int) int { return cp + 4*rp }
	w("// %s: %s 8x8 repack GEMM, SMMLA 2x2 tiles over the unpacked runs; -%d folded through the block sums.", sym, L.name, 1<<L.shift)
	w("\tMOVW\tl0+8(FP), R1")
	w("\tLSRW\t$5, R1, R1") // nb
	w("\tMOVWU\tl6+%d(FP), R7", argOff["l6"])
	w("\tLSRW\t$3, R7, R7") // column groups
	w("\tMOVWU\tl5+%d(FP), R8", argOff["l5"])
	w("\tLSRW\t$2, R8, R8") // row groups
	w("\tCBZW\tR7, gm%sdone", L.lbl)
	w("\tCBZW\tR8, gm%sdone", L.lbl)
	w("\t%s\tl1+%d(FP), R2", movArg, argOff["l1"])
	w("\t%s\tl2+%d(FP), R5", movArg, argOff["l2"])
	w("\tLSL\t$2, R5, R5") // bs floats -> bytes
	// s + (nr-1)*bs*4 + nc*4
	w("\tLSL\t$2, R8, R26")
	w("\tSUB\t$1, R26, R26")
	w("\tMUL\tR26, R5, R26")
	w("\tADD\tR2, R26, R26")
	w("\tADD\tR7<<5, R26, R26")
	w("\tCMP\tR26, R21")
	w("\tBLO\tgm%soob", L.lbl)
	w("\t%s\tl3+%d(FP), R3", movArg, argOff["l3"])
	w("\tMOVD\t$%d, R6", L.blockBytes)
	w("\tMUL\tR1, R6, R6")
	w("\tMUL\tR7, R6, R26")
	w("\tADD\tR3, R26, R26")
	w("\tCMP\tR26, R21")
	w("\tBLO\tgm%soob", L.lbl)
	w("\t%s\tl4+%d(FP), R4", movArg, argOff["l4"])
	w("\tMOVD\t$%d, R26", q8_0x4BlockBytes)
	w("\tMUL\tR1, R26, R26")
	w("\tMUL\tR8, R26, R26")
	w("\tADD\tR4, R26, R26")
	w("\tCMP\tR26, R21")
	w("\tBLO\tgm%soob", L.lbl)
	w("\tADD\tR20, R2, R2")
	w("\tADD\tR20, R3, R3")
	w("\tADD\tR20, R4, R4")
	w("\tMOVD\t$q%sscratch-%d(SP), R23", L.lbl, a64GemmQ5Scratch)
	e.loadConsts(cSym)

	w("gm%srows:", L.lbl)
	w("\tMOVD\tR3, R0")
	w("\tMOVD\tR2, R24")
	w("\tMOVW\tR7, R25")
	w("gm%scols:", L.lbl)
	e.movi4s0(8)
	for i := 0; i < 8; i++ {
		e.sturQ(8, 23, 16*i)
	}
	w("\tMOVD\tR0, R9")
	w("\tMOVD\tR4, R10")
	w("\tMOVW\tR1, R11")
	w("\tCBZW\tR11, gm%sstore", L.lbl)
	w("gm%sblk:", L.lbl)
	if L.lut {
		w("\tMOVD\t$·%s(SB), R12", cSym)
		e.ldurQ(25, 12, q5x8LUTOff) // (the epilogue reuses v25)
	}
	// the block's eight activation runs: v12+2k rows 0/1, v13+2k rows 2/3
	for k := 0; k < 4; k++ {
		e.ldurQ(12+2*k, 10, q8_0x4QsOff+32*k)
		e.ldurQ(13+2*k, 10, q8_0x4QsOff+32*k+16)
	}
	// row sums x offset: v22 = [r0 r1 r0 r1], v23 = [r2 r3 r2 r3]
	if !L.noBias {
		e.movi4s0(20)
		e.movi4s0(21)
		for k := 0; k < 4; k++ {
			e.sdot(20, 12+2*k, 26)
			e.sdot(21, 13+2*k, 26)
		}
		e.addp4s(20, 20, 21) // [r0 r1 r2 r3]
		e.shl4s(20, 20, L.shift)
		e.dup2d(22, 20, 0)
		e.dup2d(23, 20, 1)
	}
	for i := 0; i < 8; i++ {
		e.movi4s0(i)
	}
	for m := 0; m < 8; m++ {
		e.unpackL(m, 24, L)
		cp := m % 4
		kl, kh := m/4, 2+m/4
		e.smmla(acc(cp, 0), 9, 12+2*kl)
		e.smmla(acc(cp, 1), 9, 13+2*kl)
		e.smmla(acc(cp, 0), 10, 12+2*kh)
		e.smmla(acc(cp, 1), 10, 13+2*kh)
	}
	if !L.noBias {
		for cp := 0; cp < 4; cp++ {
			e.sub4s(acc(cp, 0), acc(cp, 0), 22)
			e.sub4s(acc(cp, 1), acc(cp, 1), 23)
		}
	}
	// scales: v8 = d cols 0..3, v9 = cols 4..7, v10 = activation d rows 0..3
	e.ldurD(8, 9, 0)
	e.fcvtl(8, 8)
	e.ldurD(9, 9, 8)
	e.fcvtl(9, 9)
	e.ldurD(10, 10, 0)
	e.fcvtl(10, 10)
	e.dup2d(11, 10, 0) // [a0 a1 a0 a1]
	e.dup2d(25, 10, 1) // [a2 a3 a2 a3]
	for cp := 0; cp < 4; cp++ {
		src := 8 + cp/2
		if cp%2 == 0 {
			e.zip1_4s(24, src, src) // [c c c' c']
		} else {
			e.zip2_4s(24, src, src)
		}
		e.fmul4s(20, 24, 11)
		e.fmul4s(21, 24, 25)
		for rp := 0; rp < 2; rp++ {
			a := acc(cp, rp)
			e.scvtf4s(a, a)
			e.ldurQ(24, 23, 16*a)
			if rp == 0 {
				e.fmla4s(24, a, 20)
			} else {
				e.fmla4s(24, a, 21)
			}
			e.sturQ(24, 23, 16*a)
		}
	}
	w("\tADD\t$%d, R9, R9", L.blockBytes)
	w("\tADD\t$%d, R10, R10", q8_0x4BlockBytes)
	w("\tSUBW\t$1, R11, R11")
	w("\tCBNZW\tR11, gm%sblk", L.lbl)
	w("gm%sstore:", L.lbl)
	// tile (cp, rp) lanes: [c(2cp) r(2rp), c(2cp) r(2rp+1), c(2cp+1) r(2rp), c(2cp+1) r(2rp+1)]
	for i := 0; i < 8; i++ {
		e.ldurQ(i, 23, 16*i)
	}
	w("\tMOVD\tR24, R12")
	for r := 0; r < 4; r++ {
		rp := r / 2
		for j := 0; j < 2; j++ {
			a, b := acc(2*j, rp), acc(2*j+1, rp)
			if r%2 == 0 {
				e.uzp1_4s(16, a, b)
			} else {
				e.uzp2_4s(16, a, b)
			}
			e.sturQ(16, 12, 16*j)
		}
		if r < 3 {
			w("\tADD\tR12, R5, R12")
		}
	}
	w("\tADD\t$32, R24, R24")
	w("\tADD\tR0, R6, R0")
	w("\tSUBW\t$1, R25, R25")
	w("\tCBNZW\tR25, gm%scols", L.lbl)
	w("\tMOVD\t$%d, R26", q8_0x4BlockBytes)
	w("\tMUL\tR1, R26, R26")
	w("\tADD\tR4, R26, R4")
	w("\tLSL\t$2, R5, R26")
	w("\tADD\tR2, R26, R2")
	w("\tSUBW\t$1, R8, R8")
	w("\tCBNZW\tR8, gm%srows", L.lbl)
	w("gm%sdone:", L.lbl)
	w("\tRET")
	w("gm%soob:", L.lbl)
	w("\tB\tovr_oob")
	return sb.String()
}
