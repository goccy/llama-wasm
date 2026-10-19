package asm

import (
	"fmt"
	"strings"
)

// x64VecCvtPrologue loads (x, y, n), bounds-checks both rows against the
// memory limit (xShift/yShift: log2 of the element sizes) and relocates
// them. CX = n, SI = x, DI = y.
func x64VecCvtPrologue(w func(string, ...any), args map[string]int, wide bool, xShift, yShift uint, pfx string) {
	movPtr := "MOVL"
	if wide {
		movPtr = "MOVQ"
	}
	w("\tMOVQ\tl2+%d(FP), CX", args["l2"])
	w("\tTESTQ\tCX, CX")
	w("\tJLE\t%sdone", pfx)
	w("\t%s\tl0+%d(FP), SI", movPtr, args["l0"])
	w("\t%s\tl1+%d(FP), DI", movPtr, args["l1"])
	w("\tLEAQ\t(SI)(CX*%d), R8", 1<<xShift)
	w("\tCMPQ\tR15, R8")
	w("\tJCS\t%soob", pfx)
	w("\tLEAQ\t(DI)(CX*%d), R8", 1<<yShift)
	w("\tCMPQ\tR15, R8")
	w("\tJCS\t%soob", pfx)
	w("\tADDQ\tR14, SI")
	w("\tADDQ\tR14, DI")
}

// x64VecCvtF32ToF16Kernel is the AVX2 (F16C) twin of
// a64VecCvtF32ToF16Kernel: VCVTPS2PH with round to nearest even.
func x64VecCvtF32ToF16Kernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	w := func(format string, args ...any) { fmt.Fprintf(&sb, format+"\n", args...) }
	args, _ := vecCvtArgs(wide)
	w("// %s: y = (f16) x, n elements.", sym)
	x64VecCvtPrologue(w, args, wide, 2, 1, "c3")
	w("c3loop8:")
	w("\tCMPQ\tCX, $8")
	w("\tJLT\tc3loop4")
	w("\tVMOVUPS\t(SI), Y0")
	w("\tVCVTPS2PH\t$0, Y0, X0")
	w("\tVMOVDQU\tX0, (DI)")
	w("\tADDQ\t$32, SI")
	w("\tADDQ\t$16, DI")
	w("\tSUBQ\t$8, CX")
	w("\tJMP\tc3loop8")
	w("c3loop4:")
	w("\tCMPQ\tCX, $4")
	w("\tJLT\tc3tail")
	w("\tVMOVUPS\t(SI), X0")
	w("\tVCVTPS2PH\t$0, X0, X0")
	w("\tVMOVQ\tX0, (DI)")
	w("\tADDQ\t$16, SI")
	w("\tADDQ\t$8, DI")
	w("\tSUBQ\t$4, CX")
	w("\tJMP\tc3loop4")
	w("c3tail:")
	w("\tTESTQ\tCX, CX")
	w("\tJZ\tc3done")
	w("\tVMOVSS\t(SI), X0")
	w("\tVCVTPS2PH\t$0, X0, X0")
	w("\tVPEXTRW\t$0, X0, AX")
	w("\tMOVW\tAX, (DI)")
	w("\tADDQ\t$4, SI")
	w("\tADDQ\t$2, DI")
	w("\tSUBQ\t$1, CX")
	w("\tJMP\tc3tail")
	w("c3done:")
	w("\tVZEROUPPER")
	w("\tRET")
	w("c3oob:")
	w("\tJMP\tovr_oob")
	return sb.String()
}

// x64VecCvtF16ToF32Kernel is the AVX2 (F16C) twin of
// a64VecCvtF16ToF32Kernel.
func x64VecCvtF16ToF32Kernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	w := func(format string, args ...any) { fmt.Fprintf(&sb, format+"\n", args...) }
	args, _ := vecCvtArgs(wide)
	w("// %s: y = (f32) x, n elements.", sym)
	x64VecCvtPrologue(w, args, wide, 1, 2, "c1")
	w("c1loop8:")
	w("\tCMPQ\tCX, $8")
	w("\tJLT\tc1loop4")
	w("\tVCVTPH2PS\t(SI), Y0")
	w("\tVMOVUPS\tY0, (DI)")
	w("\tADDQ\t$16, SI")
	w("\tADDQ\t$32, DI")
	w("\tSUBQ\t$8, CX")
	w("\tJMP\tc1loop8")
	w("c1loop4:")
	w("\tCMPQ\tCX, $4")
	w("\tJLT\tc1tail")
	w("\tVCVTPH2PS\t(SI), X0")
	w("\tVMOVUPS\tX0, (DI)")
	w("\tADDQ\t$8, SI")
	w("\tADDQ\t$16, DI")
	w("\tSUBQ\t$4, CX")
	w("\tJMP\tc1loop4")
	w("c1tail:")
	w("\tTESTQ\tCX, CX")
	w("\tJZ\tc1done")
	w("\tMOVWQZX\t(SI), AX")
	w("\tVMOVD\tAX, X0")
	w("\tVCVTPH2PS\tX0, X0")
	w("\tVMOVSS\tX0, (DI)")
	w("\tADDQ\t$2, SI")
	w("\tADDQ\t$4, DI")
	w("\tSUBQ\t$1, CX")
	w("\tJMP\tc1tail")
	w("c1done:")
	w("\tVZEROUPPER")
	w("\tRET")
	w("c1oob:")
	w("\tJMP\tovr_oob")
	return sb.String()
}
