package asm

import (
	"fmt"
	"strings"
)

// vecCvtArgs is the Go ABI0 frame of the row converters
// (x ptr, y ptr, n i64), with pointers 8 bytes wide when wide.
func vecCvtArgs(wide bool) (args map[string]int, argBytes int) {
	if wide {
		return map[string]int{"l0": 8, "l1": 16, "l2": 24}, 32
	}
	return map[string]int{"l0": 8, "l1": 12, "l2": 16}, 24
}

// a64VecCvt holds the NEON emitters of the arm64 f16/f32 row converters.
type a64VecCvt struct {
	w    func(format string, args ...any)
	word func(enc uint32, dis string)
}

func newA64VecCvt(sb *strings.Builder) *a64VecCvt {
	e := &a64VecCvt{}
	e.w = func(format string, args ...any) { fmt.Fprintf(sb, format+"\n", args...) }
	e.word = func(enc uint32, dis string) { e.w("\tWORD $0x%08x // %s", enc, dis) }
	return e
}

func (e *a64VecCvt) ldurQ(rt, rn, imm int) {
	e.word(0x3CC00000|uint32(imm&0x1ff)<<12|uint32(rn)<<5|uint32(rt), fmt.Sprintf("ldur q%d, [x%d, #%d]", rt, rn, imm))
}

func (e *a64VecCvt) sturQ(rt, rn, imm int) {
	e.word(0x3C800000|uint32(imm&0x1ff)<<12|uint32(rn)<<5|uint32(rt), fmt.Sprintf("stur q%d, [x%d, #%d]", rt, rn, imm))
}

// fcvtn narrows the four floats of v<n> into the low four halves of
// v<d>; fcvtn2 into the high four.
func (e *a64VecCvt) fcvtn(d, n int) {
	e.word(0x0E216800|uint32(n)<<5|uint32(d), fmt.Sprintf("fcvtn v%d.4h, v%d.4s", d, n))
}

func (e *a64VecCvt) fcvtn2(d, n int) {
	e.word(0x4E216800|uint32(n)<<5|uint32(d), fmt.Sprintf("fcvtn2 v%d.8h, v%d.4s", d, n))
}

// fcvtl widens the low four halves of v<n>; fcvtl2 the high four.
func (e *a64VecCvt) fcvtl(d, n int) {
	e.word(0x0E217800|uint32(n)<<5|uint32(d), fmt.Sprintf("fcvtl v%d.4s, v%d.4h", d, n))
}

func (e *a64VecCvt) fcvtl2(d, n int) {
	e.word(0x4E217800|uint32(n)<<5|uint32(d), fmt.Sprintf("fcvtl2 v%d.4s, v%d.8h", d, n))
}

// Scalar half conversions and 16-bit SIMD&FP loads/stores.
func (e *a64VecCvt) fcvtHS(d, n int) {
	e.word(0x1E23C000|uint32(n)<<5|uint32(d), fmt.Sprintf("fcvt h%d, s%d", d, n))
}

func (e *a64VecCvt) fcvtSH(d, n int) {
	e.word(0x1EE24000|uint32(n)<<5|uint32(d), fmt.Sprintf("fcvt s%d, h%d", d, n))
}

func (e *a64VecCvt) ldrH(rt, rn int) {
	e.word(0x7D400000|uint32(rn)<<5|uint32(rt), fmt.Sprintf("ldr h%d, [x%d]", rt, rn))
}

func (e *a64VecCvt) strH(rt, rn int) {
	e.word(0x7D000000|uint32(rn)<<5|uint32(rt), fmt.Sprintf("str h%d, [x%d]", rt, rn))
}

// prologue loads (x, y, n), bounds-checks x (xBytes per element) and y
// (yBytes per element) against the memory limit and relocates both.
func (e *a64VecCvt) prologue(args map[string]int, wide bool, xShift, yShift uint, pfx string) {
	movPtr := "MOVWU"
	if wide {
		movPtr = "MOVD"
	}
	e.w("\tMOVD\tl2+%d(FP), R1", args["l2"])
	e.w("\tCMP\t$1, R1")
	e.w("\tBLT\t%sdone", pfx)
	e.w("\t%s\tl0+%d(FP), R3", movPtr, args["l0"])
	e.w("\t%s\tl1+%d(FP), R2", movPtr, args["l1"])
	e.w("\tLSL\t$%d, R1, R26", xShift)
	e.w("\tADD\tR3, R26, R27")
	e.w("\tCMP\tR27, R21")
	e.w("\tBLO\t%soob", pfx)
	e.w("\tLSL\t$%d, R1, R26", yShift)
	e.w("\tADD\tR2, R26, R27")
	e.w("\tCMP\tR27, R21")
	e.w("\tBLO\t%soob", pfx)
	e.w("\tADD\tR20, R3, R3")
	e.w("\tADD\tR20, R2, R2")
}

// a64VecCvtF32ToF16Kernel emits ggml_cpu_fp32_to_fp16 under sym: y[i] =
// (half) x[i] for n elements, round to nearest even.
func a64VecCvtF32ToF16Kernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	e := newA64VecCvt(&sb)
	args, _ := vecCvtArgs(wide)
	w := e.w
	w("// %s: y = (f16) x, n elements.", sym)
	e.prologue(args, wide, 2, 1, "c3")
	w("c3loop8:")
	w("\tCMP\t$8, R1")
	w("\tBLT\tc3loop4")
	e.ldurQ(0, 3, 0)
	e.ldurQ(1, 3, 16)
	e.fcvtn(2, 0)
	e.fcvtn2(2, 1)
	e.sturQ(2, 2, 0)
	w("\tADD\t$32, R3, R3")
	w("\tADD\t$16, R2, R2")
	w("\tSUB\t$8, R1, R1")
	w("\tB\tc3loop8")
	w("c3loop4:")
	w("\tCMP\t$4, R1")
	w("\tBLT\tc3tail")
	e.ldurQ(0, 3, 0)
	e.fcvtn(2, 0)
	w("\tFMOVD\tF2, (R2)")
	w("\tADD\t$16, R3, R3")
	w("\tADD\t$8, R2, R2")
	w("\tSUB\t$4, R1, R1")
	w("\tB\tc3loop4")
	w("c3tail:")
	w("\tCBZ\tR1, c3done")
	w("\tFMOVS\t(R3), F0")
	e.fcvtHS(0, 0)
	e.strH(0, 2)
	w("\tADD\t$4, R3, R3")
	w("\tADD\t$2, R2, R2")
	w("\tSUB\t$1, R1, R1")
	w("\tB\tc3tail")
	w("c3done:")
	w("\tRET")
	w("c3oob:")
	w("\tB\tovr_oob")
	return sb.String()
}

// a64VecCvtF16ToF32Kernel emits ggml_cpu_fp16_to_fp32 under sym: y[i] =
// (float) x[i] for n elements.
func a64VecCvtF16ToF32Kernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	e := newA64VecCvt(&sb)
	args, _ := vecCvtArgs(wide)
	w := e.w
	w("// %s: y = (f32) x, n elements.", sym)
	e.prologue(args, wide, 1, 2, "c1")
	w("c1loop8:")
	w("\tCMP\t$8, R1")
	w("\tBLT\tc1loop4")
	e.ldurQ(0, 3, 0)
	e.fcvtl(1, 0)
	e.fcvtl2(2, 0)
	e.sturQ(1, 2, 0)
	e.sturQ(2, 2, 16)
	w("\tADD\t$16, R3, R3")
	w("\tADD\t$32, R2, R2")
	w("\tSUB\t$8, R1, R1")
	w("\tB\tc1loop8")
	w("c1loop4:")
	w("\tCMP\t$4, R1")
	w("\tBLT\tc1tail")
	w("\tFMOVD\t(R3), F0")
	e.fcvtl(1, 0)
	e.sturQ(1, 2, 0)
	w("\tADD\t$8, R3, R3")
	w("\tADD\t$16, R2, R2")
	w("\tSUB\t$4, R1, R1")
	w("\tB\tc1loop4")
	w("c1tail:")
	w("\tCBZ\tR1, c1done")
	e.ldrH(0, 3)
	e.fcvtSH(0, 0)
	w("\tFMOVS\tF0, (R2)")
	w("\tADD\t$2, R3, R3")
	w("\tADD\t$4, R2, R2")
	w("\tSUB\t$1, R1, R1")
	w("\tB\tc1tail")
	w("c1done:")
	w("\tRET")
	w("c1oob:")
	w("\tB\tovr_oob")
	return sb.String()
}
