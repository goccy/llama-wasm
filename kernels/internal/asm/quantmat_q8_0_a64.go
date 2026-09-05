package asm

import (
	"fmt"
	"strings"
)

// ggml_quantize_mat_q8_0_4x8 (exported by llama-wasm as
// dbg_quantize_mat_q8_0_4x8): four f32 rows of k elements into k/32
// block_q8_0x4 blocks, the activation layout of the 8-wide q8_0 repack
// GEMMs (Q5_0 8x8 here). ggml has only the scalar body: per row and
// block d = amax/127, id = 1/d, q = round-to-nearest-even(x * id)
// (FCVTNS: the rounding of quantize_row_q8_0 and of every native SIMD
// quantizer; ggml's scalar body rounds ties away with roundf, and the
// llama-wasm patch aligns it to nearest-even so the GEMM path, fed by
// this function, quantizes exactly like the GEMV path, fed by
// quantize_row_q8_0), quants of eight consecutive elements of row m at
// qs[32k + 8m], d[m] as f16.
//
// C signature: void f(const float *x, void *vy, int64_t k); k is a
// multiple of 32 (asserted by ggml). Block layout (136 bytes): d[4] f16
// (0) | qs[128] (8).

// a64QuantizeMatQ8_0_4x8Kernel emits the kernel under sym.
//
// Registers: R1 x, R2 vy (block, advancing), R3 row stride bytes, R4
// blocks left, R5 rows left, R6 row's block start, R7 vy + 8r (qs row
// base), R8 vy + 2r (d). v0..v7 the row's 32 floats, v8 amax scratch,
// v9 id broadcast, v10..v13 quantize scratch, v14 = 127.0, v15 = 1.0.
func a64QuantizeMatQ8_0_4x8Kernel(sym string, wide bool) string {
	var sb strings.Builder
	e := newA64Q(&sb)
	w := e.w
	word := e.word
	args, _ := quantMatArgs(wide)
	movPtr := "MOVWU"
	if wide {
		movPtr = "MOVD"
	}
	fabs4s := func(d, n int) { word(0x4EA0F800|uint32(n)<<5|uint32(d), fmt.Sprintf("fabs v%d.4s, v%d.4s", d, n)) }
	fmax4s := func(d, n, m int) {
		word(0x4E20F400|lane3(d, n, m), fmt.Sprintf("fmax v%d.4s, v%d.4s, v%d.4s", d, n, m))
	}
	fmaxvS := func(d, n int) { word(0x6E30F800|uint32(n)<<5|uint32(d), fmt.Sprintf("fmaxv s%d, v%d.4s", d, n)) }
	fcvtns4s := func(d, n int) { word(0x4E21A800|uint32(n)<<5|uint32(d), fmt.Sprintf("fcvtns v%d.4s, v%d.4s", d, n)) }
	sqxtn4h := func(d, n int) { word(0x0E614800|uint32(n)<<5|uint32(d), fmt.Sprintf("sqxtn v%d.4h, v%d.4s", d, n)) }
	sqxtn2_8h := func(d, n int) { word(0x4E614800|uint32(n)<<5|uint32(d), fmt.Sprintf("sqxtn2 v%d.8h, v%d.4s", d, n)) }
	sqxtn8b := func(d, n int) { word(0x0E214800|uint32(n)<<5|uint32(d), fmt.Sprintf("sqxtn v%d.8b, v%d.8h", d, n)) }
	fdivS := func(d, n, m int) { word(0x1E201800|lane3(d, n, m), fmt.Sprintf("fdiv s%d, s%d, s%d", d, n, m)) }
	fcmpS0 := func(n int) { word(0x1E202008|uint32(n)<<5, fmt.Sprintf("fcmp s%d, #0.0", n)) }
	fcvtHS := func(d, n int) { word(0x1E23C000|uint32(n)<<5|uint32(d), fmt.Sprintf("fcvt h%d, s%d", d, n)) }
	fmovS1 := func(d int) { word(0x1E2E1000|uint32(d), fmt.Sprintf("fmov s%d, #1.0", d)) }
	fmovSW := func(d, n int) { word(0x1E270000|uint32(n)<<5|uint32(d), fmt.Sprintf("fmov s%d, w%d", d, n)) }
	fmovSzr := func(d int) { word(0x1E2703E0|uint32(d), fmt.Sprintf("fmov s%d, wzr", d)) }
	dupS0 := func(d, n int) { word(0x4E040400|uint32(n)<<5|uint32(d), fmt.Sprintf("dup v%d.4s, v%d.s[0]", d, n)) }
	strD := func(rt, rn, off int) {
		word(0xFD000000|uint32(off/8)<<10|uint32(rn)<<5|uint32(rt), fmt.Sprintf("str d%d, [x%d, #%d]", rt, rn, off))
	}
	strH := func(rt, rn, off int) {
		word(0x7D000000|uint32(off/2)<<10|uint32(rn)<<5|uint32(rt), fmt.Sprintf("str h%d, [x%d, #%d]", rt, rn, off))
	}
	ldrQ := func(rt, rn, off int) {
		word(0x3DC00000|uint32(off/16)<<10|uint32(rn)<<5|uint32(rt), fmt.Sprintf("ldr q%d, [x%d, #%d]", rt, rn, off))
	}

	w("// %s: quantize four f32 rows into block_q8_0x4 (FMAXV amax, FCVTAS quants).", sym)
	w("\t%s\tl0+%d(FP), R1", movPtr, args["l0"])
	w("\t%s\tl1+%d(FP), R2", movPtr, args["l1"])
	w("\tMOVD\tl2+%d(FP), R3", args["l2"])
	w("\tLSR\t$5, R3, R4") // blocks
	w("\tCBZ\tR4, q8mdone")
	w("\tLSL\t$2, R3, R3") // row stride in bytes
	w("\tADD\tR3<<2, R1, R27")
	w("\tCMP\tR27, R21")
	w("\tBLO\tq8moob")
	w("\tMOVD\t$%d, R26", q8_0x4BlockBytes)
	w("\tMUL\tR4, R26, R26")
	w("\tADD\tR2, R26, R27")
	w("\tCMP\tR27, R21")
	w("\tBLO\tq8moob")
	w("\tADD\tR20, R1, R1")
	w("\tADD\tR20, R2, R2")
	w("\tMOVW\t$0x42fe0000, R11") // 127.0f
	fmovSW(14, 11)
	fmovS1(15)
	w("q8mblk:")
	w("\tMOVD\tR1, R6")
	w("\tMOVD\tR2, R7")
	w("\tMOVD\tR2, R8")
	w("\tMOVW\t$4, R5")
	w("q8mrow:")
	for i := 0; i < 8; i++ {
		ldrQ(i, 6, 16*i)
	}
	// amax = max |x|
	fabs4s(8, 0)
	for i := 1; i < 8; i++ {
		fabs4s(10, i)
		fmax4s(8, 8, 10)
	}
	fmaxvS(8, 8)
	// d = amax / 127; id = amax ? 1/d : 0
	fdivS(10, 8, 14)
	fcmpS0(8)
	w("\tBEQ\tq8mzero")
	fdivS(9, 15, 10)
	w("\tB\tq8mscale")
	w("q8mzero:")
	fmovSzr(9)
	w("q8mscale:")
	fcvtHS(10, 10)
	strH(10, 8, 0)
	dupS0(9, 9)
	for k := 0; k < 4; k++ {
		e.fmul4s(10, 2*k, 9)
		e.fmul4s(11, 2*k+1, 9)
		fcvtns4s(10, 10)
		fcvtns4s(11, 11)
		sqxtn4h(12, 10)
		sqxtn2_8h(12, 11)
		sqxtn8b(13, 12)
		strD(13, 7, q8_0x4QsOff+32*k)
	}
	w("\tADD\tR6, R3, R6")
	w("\tADD\t$8, R7, R7")
	w("\tADD\t$2, R8, R8")
	w("\tSUBW\t$1, R5, R5")
	w("\tCBNZW\tR5, q8mrow")
	w("\tADD\t$128, R1, R1")
	w("\tADD\t$%d, R2, R2", q8_0x4BlockBytes)
	w("\tSUB\t$1, R4, R4")
	w("\tCBNZ\tR4, q8mblk")
	w("q8mdone:")
	w("\tRET")
	w("q8moob:")
	w("\tB\tovr_oob")
	return sb.String()
}
