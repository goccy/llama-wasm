package asm

import (
	"fmt"
	"strings"
)

// a64QuantizeMatQ8_0_4x4Kernel emits ggml_quantize_mat_q8_0_4x4 under
// sym: four f32 rows of k elements into k/32 block_q8_0x4 blocks in the
// 4-wide interleave of the i8mm q8_0 repack GEMM — qs[16j + 4m] holds
// four consecutive elements of row m. Per row and block d = amax/127,
// id = 1/d (0 when d is 0), q = round-to-nearest-even(x * id)
// (FCVTNS), d stored as f16. Block layout (136 bytes): d[4] f16 (0) |
// qs[128] (8).
//
// Two passes per block: the amax/scale pass walks the rows (R6 row
// start, R8 the d slot, v16..v19 the broadcast scales), the quantize
// pass walks the eight column groups across the four rows (R1, R9,
// R10, R11 the row starts) and stores one 16-byte group per step.
func a64QuantizeMatQ8_0_4x4Kernel(sym string, wide bool) string {
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
	sqxtn2_16b := func(d, n int) { word(0x4E214800|uint32(n)<<5|uint32(d), fmt.Sprintf("sqxtn2 v%d.16b, v%d.8h", d, n)) }
	fdivS := func(d, n, m int) { word(0x1E201800|lane3(d, n, m), fmt.Sprintf("fdiv s%d, s%d, s%d", d, n, m)) }
	fcmpS0 := func(n int) { word(0x1E202008|uint32(n)<<5, fmt.Sprintf("fcmp s%d, #0.0", n)) }
	fcvtHS := func(d, n int) { word(0x1E23C000|uint32(n)<<5|uint32(d), fmt.Sprintf("fcvt h%d, s%d", d, n)) }
	fmovS1 := func(d int) { word(0x1E2E1000|uint32(d), fmt.Sprintf("fmov s%d, #1.0", d)) }
	fmovSW := func(d, n int) { word(0x1E270000|uint32(n)<<5|uint32(d), fmt.Sprintf("fmov s%d, w%d", d, n)) }
	fmovSzr := func(d int) { word(0x1E2703E0|uint32(d), fmt.Sprintf("fmov s%d, wzr", d)) }
	dupS0 := func(d, n int) { word(0x4E040400|uint32(n)<<5|uint32(d), fmt.Sprintf("dup v%d.4s, v%d.s[0]", d, n)) }
	strH := func(rt, rn, off int) {
		word(0x7D000000|uint32(off/2)<<10|uint32(rn)<<5|uint32(rt), fmt.Sprintf("str h%d, [x%d, #%d]", rt, rn, off))
	}
	ldrQ := func(rt, rn, off int) {
		word(0x3DC00000|uint32(off/16)<<10|uint32(rn)<<5|uint32(rt), fmt.Sprintf("ldr q%d, [x%d, #%d]", rt, rn, off))
	}
	sturQ := func(rt, rn, off int) {
		word(0x3C800000|uint32(off&0x1ff)<<12|uint32(rn)<<5|uint32(rt), fmt.Sprintf("stur q%d, [x%d, #%d]", rt, rn, off))
	}

	w("// %s: quantize four f32 rows into block_q8_0x4, 4-wide interleave (FMAXV amax, FCVTNS quants).", sym)
	w("\t%s\tl0+%d(FP), R1", movPtr, args["l0"])
	w("\t%s\tl1+%d(FP), R2", movPtr, args["l1"])
	w("\tMOVD\tl2+%d(FP), R3", args["l2"])
	w("\tLSR\t$5, R3, R4") // blocks
	w("\tCBZ\tR4, q44done")
	w("\tLSL\t$2, R3, R3") // row stride in bytes
	w("\tADD\tR3<<2, R1, R27")
	w("\tCMP\tR27, R21")
	w("\tBLO\tq44oob")
	w("\tMOVD\t$%d, R26", q8_0x4BlockBytes)
	w("\tMUL\tR4, R26, R26")
	w("\tADD\tR2, R26, R27")
	w("\tCMP\tR27, R21")
	w("\tBLO\tq44oob")
	w("\tADD\tR20, R1, R1")
	w("\tADD\tR20, R2, R2")
	w("\tMOVW\t$0x42fe0000, R11") // 127.0f
	fmovSW(14, 11)
	fmovS1(15)
	w("\tADD\tR1, R3, R9")
	w("\tADD\tR9, R3, R10")
	w("\tADD\tR10, R3, R11")
	w("q44blk:")
	// Pass 1: amax, d (stored as f16) and the broadcast id per row.
	w("\tMOVD\tR1, R6")
	w("\tMOVD\tR2, R8")
	for m := 0; m < 4; m++ {
		for i := 0; i < 8; i++ {
			ldrQ(i, 6, 16*i)
		}
		fabs4s(8, 0)
		for i := 1; i < 8; i++ {
			fabs4s(10, i)
			fmax4s(8, 8, 10)
		}
		fmaxvS(8, 8)
		fdivS(10, 8, 14)
		fcmpS0(8)
		w("\tBEQ\tq44zero%d", m)
		fdivS(9, 15, 10)
		w("\tB\tq44scale%d", m)
		w("q44zero%d:", m)
		fmovSzr(9)
		w("q44scale%d:", m)
		fcvtHS(10, 10)
		strH(10, 8, 2*m)
		dupS0(16+m, 9)
		if m < 3 {
			w("\tADD\tR6, R3, R6")
		}
	}
	// Pass 2: eight column groups, four rows each, one 16-byte store.
	for j := 0; j < 8; j++ {
		ldrQ(0, 1, 16*j)
		ldrQ(1, 9, 16*j)
		ldrQ(2, 10, 16*j)
		ldrQ(3, 11, 16*j)
		for m := 0; m < 4; m++ {
			e.fmul4s(m, m, 16+m)
			fcvtns4s(m, m)
		}
		sqxtn4h(4, 0)
		sqxtn2_8h(4, 1)
		sqxtn4h(5, 2)
		sqxtn2_8h(5, 3)
		sqxtn8b(6, 4)
		sqxtn2_16b(6, 5)
		sturQ(6, 2, q8_0x4QsOff+16*j)
	}
	w("\tADD\t$128, R1, R1")
	w("\tADD\t$128, R9, R9")
	w("\tADD\t$128, R10, R10")
	w("\tADD\t$128, R11, R11")
	w("\tADD\t$%d, R2, R2", q8_0x4BlockBytes)
	w("\tSUB\t$1, R4, R4")
	w("\tCBNZ\tR4, q44blk")
	w("q44done:")
	w("\tRET")
	w("q44oob:")
	w("\tB\tovr_oob")
	return sb.String()
}
