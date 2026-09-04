package asm

import (
	"fmt"
	"strings"
)

// ggml_quantize_mat_q8_K_4x8 (exported by llama-wasm as
// dbg_quantize_mat_q8_K_4x8): quantizes four f32 rows of k elements into
// k/256 block_q8_Kx4 blocks, the activation layout of the q4_K_8x8
// repack GEMM. ggml only has the scalar body for this (every
// architecture runs it), so the transpiled loop is the repack driver's
// whole non-kernel cost on the prompt path.
//
// Per block and row: the signed element of largest magnitude (max),
// iscale = -127/max, d = 1/iscale (the C arithmetic, so d matches bit
// for bit), q = nearest(x * iscale) with FCVTNS (ties to even, the
// rounding of nearest_int's magic-number add). The quants of eight
// consecutive elements of row r land at qs[32g + 8r] for group g; the
// 16-element chunk sums at bsums[4r + 16(c/4) + c%4] for chunk c.
//
// C signature: void f(const float *x, void *vy, int64_t k); k is a
// multiple of 256 (asserted by ggml).
//
// Block layout (bytes): d[4] f32 (0) | qs[1024] (16) | bsums[64] i16
// (1040), 1168 total.

func quantMatArgs(wide bool) (map[string]int, int) {
	if wide {
		return map[string]int{"l0": 8, "l1": 16, "l2": 24}, 32
	}
	return map[string]int{"l0": 8, "l1": 12, "l2": 16}, 24
}

// a64QuantizeMatQ8K4x8Kernel emits the kernel under sym.
//
// Registers: R1 x, R2 vy (block, advancing), R3 k*4 (row stride bytes),
// R4 blocks left, R5 rows left, R6 row's block start (x + r*stride +
// 1024*i), R7 vy + 8r (qs and bsums row base), R8 vy + 4r (d), R9 loop
// counter, R10 pass-1 pointer. Vectors: v0 max, v1 min, v2..v5 loads,
// v6 -min / amax scratch, v7 iscale broadcast, v8..v13 pass-2 scratch.
func a64QuantizeMatQ8K4x8Kernel(sym string, wide bool) string {
	var sb strings.Builder
	e := newA64Q(&sb)
	w := e.w
	word := e.word
	args, _ := quantMatArgs(wide)
	movPtr := "MOVWU"
	if wide {
		movPtr = "MOVD"
	}
	fmax4s := func(d, n, m int) {
		word(0x4E20F400|lane3(d, n, m), fmt.Sprintf("fmax v%d.4s, v%d.4s, v%d.4s", d, n, m))
	}
	fmin4s := func(d, n, m int) {
		word(0x4EA0F400|lane3(d, n, m), fmt.Sprintf("fmin v%d.4s, v%d.4s, v%d.4s", d, n, m))
	}
	fmaxvS := func(d, n int) { word(0x6E30F800|uint32(n)<<5|uint32(d), fmt.Sprintf("fmaxv s%d, v%d.4s", d, n)) }
	fminvS := func(d, n int) { word(0x6EB0F800|uint32(n)<<5|uint32(d), fmt.Sprintf("fminv s%d, v%d.4s", d, n)) }
	fcvtns4s := func(d, n int) { word(0x4E21A800|uint32(n)<<5|uint32(d), fmt.Sprintf("fcvtns v%d.4s, v%d.4s", d, n)) }
	sqxtn4h := func(d, n int) { word(0x0E614800|uint32(n)<<5|uint32(d), fmt.Sprintf("sqxtn v%d.4h, v%d.4s", d, n)) }
	sqxtn2_8h := func(d, n int) { word(0x4E614800|uint32(n)<<5|uint32(d), fmt.Sprintf("sqxtn2 v%d.8h, v%d.4s", d, n)) }
	sqxtn8b := func(d, n int) { word(0x0E214800|uint32(n)<<5|uint32(d), fmt.Sprintf("sqxtn v%d.8b, v%d.8h", d, n)) }
	fdivS := func(d, n, m int) { word(0x1E201800|lane3(d, n, m), fmt.Sprintf("fdiv s%d, s%d, s%d", d, n, m)) }
	fnegS := func(d, n int) { word(0x1E214000|uint32(n)<<5|uint32(d), fmt.Sprintf("fneg s%d, s%d", d, n)) }
	fcmpS0 := func(n int) { word(0x1E202008|uint32(n)<<5, fmt.Sprintf("fcmp s%d, #0.0", n)) }
	fcmpS := func(n, m int) { word(0x1E202000|uint32(m)<<16|uint32(n)<<5, fmt.Sprintf("fcmp s%d, s%d", n, m)) }
	fcselGE := func(d, n, m int) { word(0x1E20AC00|lane3(d, n, m), fmt.Sprintf("fcsel s%d, s%d, s%d, ge", d, n, m)) }
	fmovS1 := func(d int) { word(0x1E2E1000|uint32(d), fmt.Sprintf("fmov s%d, #1.0", d)) }
	fmovSzr := func(d int) { word(0x1E2703E0|uint32(d), fmt.Sprintf("fmov s%d, wzr", d)) }
	fmovSW := func(d, n int) { word(0x1E270000|uint32(n)<<5|uint32(d), fmt.Sprintf("fmov s%d, w%d", d, n)) }
	dupS0 := func(d, n int) { word(0x4E040400|uint32(n)<<5|uint32(d), fmt.Sprintf("dup v%d.4s, v%d.s[0]", d, n)) }
	addvH := func(d, n int) { word(0x4E71B800|uint32(n)<<5|uint32(d), fmt.Sprintf("addv h%d, v%d.8h", d, n)) }
	add8h := func(d, n, m int) { word(0x4E608400|lane3(d, n, m), fmt.Sprintf("add v%d.8h, v%d.8h, v%d.8h", d, n, m)) }
	strD := func(rt, rn, off int) {
		word(0xFD000000|uint32(off/8)<<10|uint32(rn)<<5|uint32(rt), fmt.Sprintf("str d%d, [x%d, #%d]", rt, rn, off))
	}
	strH := func(rt, rn, off int) {
		word(0x7D000000|uint32(off/2)<<10|uint32(rn)<<5|uint32(rt), fmt.Sprintf("str h%d, [x%d, #%d]", rt, rn, off))
	}
	strS := func(rt, rn, off int) {
		word(0xBD000000|uint32(off/4)<<10|uint32(rn)<<5|uint32(rt), fmt.Sprintf("str s%d, [x%d, #%d]", rt, rn, off))
	}
	ldrQ := func(rt, rn, off int) {
		word(0x3DC00000|uint32(off/16)<<10|uint32(rn)<<5|uint32(rt), fmt.Sprintf("ldr q%d, [x%d, #%d]", rt, rn, off))
	}
	ldrQPost := func(rt, rn int) {
		word(0x3CC10400|uint32(rn)<<5|uint32(rt), fmt.Sprintf("ldr q%d, [x%d], #16", rt, rn))
	}
	movV := func(d, n int) {
		word(0x4EA01C00|uint32(n)<<16|uint32(n)<<5|uint32(d), fmt.Sprintf("mov v%d.16b, v%d.16b", d, n))
	}

	w("// %s: quantize four f32 rows into block_q8_Kx4 (FMAXV/FMINV max, FCVTNS quants, ADDV chunk sums).", sym)
	w("\t%s\tl0+%d(FP), R1", movPtr, args["l0"])
	w("\t%s\tl1+%d(FP), R2", movPtr, args["l1"])
	w("\tMOVD\tl2+%d(FP), R3", args["l2"])
	w("\tLSR\t$8, R3, R4") // blocks
	w("\tCBZ\tR4, qmdone")
	w("\tLSL\t$2, R3, R3") // row stride in bytes
	// x + 4 rows * stride, vy + nb * 1168 must fit.
	w("\tADD\tR3<<2, R1, R27")
	w("\tCMP\tR27, R21")
	w("\tBLO\tqmoob")
	w("\tMOVD\t$%d, R26", q8Kx4BlockBytes)
	w("\tMUL\tR4, R26, R26")
	w("\tADD\tR2, R26, R27")
	w("\tCMP\tR27, R21")
	w("\tBLO\tqmoob")
	w("\tADD\tR20, R1, R1")
	w("\tADD\tR20, R2, R2")
	w("\tMOVW\t$0x42fe0000, R11") // 127.0f
	fmovSW(14, 11)
	fmovS1(15)
	w("qmblk:")
	w("\tMOVD\tR1, R6")
	w("\tMOVD\tR2, R7")
	w("\tMOVD\tR2, R8")
	w("\tMOVW\t$4, R5")
	w("qmrow:")
	// --- pass 1: max and min over the 256 elements.
	w("\tMOVD\tR6, R10")
	ldrQ(0, 10, 0)
	movV(1, 0)
	w("\tMOVW\t$16, R9")
	w("qmmax:")
	for i := 0; i < 4; i++ {
		ldrQPost(2+i, 10)
	}
	for i := 0; i < 4; i++ {
		fmax4s(0, 0, 2+i)
		fmin4s(1, 1, 2+i)
	}
	w("\tSUBW\t$1, R9, R9")
	w("\tCBNZW\tR9, qmmax")
	fmaxvS(0, 0)
	fminvS(1, 1)
	fnegS(6, 1)
	// max = (maxv >= -minv) ? maxv : minv; amax = max(maxv, -minv)
	fcmpS(0, 6)
	fcselGE(2, 0, 1)
	fcselGE(6, 0, 6)
	// amax == 0: iscale = d = 0
	fcmpS0(6)
	w("\tBEQ\tqmzero")
	fdivS(7, 14, 2) // 127 / max
	fnegS(7, 7)     // iscale
	fdivS(3, 15, 7) // d = 1 / iscale
	w("\tB\tqmscale")
	w("qmzero:")
	fmovSzr(7)
	fmovSzr(3)
	w("qmscale:")
	strS(3, 8, 0)
	dupS0(7, 7)
	// --- pass 2: quantize the 32 groups of eight; chunk sums per 16.
	for g := 0; g < 32; g++ {
		ldrQ(8, 6, 32*g)
		ldrQ(9, 6, 32*g+16)
		e.fmul4s(8, 8, 7)
		e.fmul4s(9, 9, 7)
		fcvtns4s(8, 8)
		fcvtns4s(9, 9)
		sqxtn4h(10, 8)
		sqxtn2_8h(10, 9)
		sqxtn8b(11, 10)
		strD(11, 7, q8Kx4QsOff+32*g)
		if g%2 == 0 {
			movV(12, 10)
		} else {
			add8h(12, 12, 10)
			addvH(13, 12)
			c := g / 2
			strH(13, 7, q8Kx4BsumsOff+32*(c/4)+2*(c%4))
		}
	}
	w("\tADD\tR6, R3, R6")
	w("\tADD\t$8, R7, R7")
	w("\tADD\t$4, R8, R8")
	w("\tSUBW\t$1, R5, R5")
	w("\tCBNZW\tR5, qmrow")
	w("\tADD\t$1024, R1, R1")
	w("\tADD\t$%d, R2, R2", q8Kx4BlockBytes)
	w("\tSUB\t$1, R4, R4")
	w("\tCBNZ\tR4, qmblk")
	w("qmdone:")
	w("\tRET")
	w("qmoob:")
	w("\tB\tovr_oob")
	return sb.String()
}
