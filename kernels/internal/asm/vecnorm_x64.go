package asm

import (
	"fmt"
	"strings"
)

// x64GroupSum adds the f32 lanes of W0 in groups of four as
// (l0+l1)+(l2+l3), widens each group sum and accumulates it into X15 in
// lane order, the arithmetic of the C body. X0/X1 are clobbered.
func x64GroupSum(w func(string, ...any), W string) {
	w("\tVHADDPS\t%s0, %s0, %s0", W, W, W)
	w("\tVHADDPS\t%s0, %s0, %s0", W, W, W)
	w("\tVCVTSS2SD\tX0, X0, X1")
	w("\tVADDSD\tX1, X15, X15")
	if W == "Y" {
		w("\tVEXTRACTF128\t$1, Y0, X0")
		w("\tVCVTSS2SD\tX0, X0, X1")
		w("\tVADDSD\tX1, X15, X15")
	}
}

// x64VecSumKernel is the AVX2 twin of a64VecSumKernel.
func x64VecSumKernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	w := func(format string, args ...any) { fmt.Fprintf(&sb, format+"\n", args...) }
	args, _ := vecNormArgs(wide)
	movPtr := "MOVL"
	if wide {
		movPtr = "MOVQ"
	}
	w("// %s: returns sum(x) (f64).", sym)
	w("\tVXORPS\tX15, X15, X15")
	w("\tMOVLQSX\tl0+%d(FP), CX", args["l0"])
	w("\tTESTQ\tCX, CX")
	w("\tJLE\tvsdone")
	w("\t%s\tl1+%d(FP), SI", movPtr, args["l1"])
	w("\tLEAQ\t(SI)(CX*4), R8")
	w("\tCMPQ\tR15, R8")
	w("\tJCS\tvsoob")
	w("\tADDQ\tR14, SI")
	w("vsloop8:")
	w("\tCMPQ\tCX, $8")
	w("\tJLT\tvsloop4")
	w("\tVMOVUPS\t(SI), Y0")
	x64GroupSum(w, "Y")
	w("\tADDQ\t$32, SI")
	w("\tSUBQ\t$8, CX")
	w("\tJMP\tvsloop8")
	w("vsloop4:")
	w("\tCMPQ\tCX, $4")
	w("\tJLT\tvstail")
	w("\tVMOVUPS\t(SI), X0")
	x64GroupSum(w, "X")
	w("\tADDQ\t$16, SI")
	w("\tSUBQ\t$4, CX")
	w("\tJMP\tvsloop4")
	w("vstail:")
	w("\tTESTQ\tCX, CX")
	w("\tJZ\tvsdone")
	w("\tVMOVSS\t(SI), X0")
	w("\tVCVTSS2SD\tX0, X0, X0")
	w("\tVADDSD\tX0, X15, X15")
	w("\tADDQ\t$4, SI")
	w("\tSUBQ\t$1, CX")
	w("\tJMP\tvstail")
	w("vsdone:")
	w("\tVMOVSD\tX15, r0+%d(FP)", args["r0"])
	w("\tVZEROUPPER")
	w("\tRET")
	w("vsoob:")
	w("\tJMP\tovr_oob")
	return sb.String()
}

// x64VecCvarKernel is the AVX2 twin of a64VecCvarKernel.
func x64VecCvarKernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	w := func(format string, args ...any) { fmt.Fprintf(&sb, format+"\n", args...) }
	args, _, _, _ := vecExpArgs(wide)
	movPtr := "MOVL"
	if wide {
		movPtr = "MOVQ"
	}
	w("// %s: y = x - mean, returns sum(y*y)/n (f64).", sym)
	w("\tVXORPS\tX15, X15, X15")
	w("\tMOVLQSX\tl0+%d(FP), CX", args["l0"])
	w("\tTESTQ\tCX, CX")
	w("\tJLE\tcvdone")
	w("\tMOVQ\tCX, R9")
	w("\t%s\tl1+%d(FP), DI", movPtr, args["l1"])
	w("\t%s\tl2+%d(FP), SI", movPtr, args["l2"])
	w("\tLEAQ\t(DI)(CX*4), R8")
	w("\tCMPQ\tR15, R8")
	w("\tJCS\tcvoob")
	w("\tLEAQ\t(SI)(CX*4), R8")
	w("\tCMPQ\tR15, R8")
	w("\tJCS\tcvoob")
	w("\tADDQ\tR14, DI")
	w("\tADDQ\tR14, SI")
	w("\tVBROADCASTSS\tl3+%d(FP), Y14", args["l3"])
	w("cvloop8:")
	w("\tCMPQ\tCX, $8")
	w("\tJLT\tcvloop4")
	w("\tVMOVUPS\t(SI), Y0")
	w("\tVSUBPS\tY14, Y0, Y0")
	w("\tVMOVUPS\tY0, (DI)")
	w("\tVMULPS\tY0, Y0, Y0")
	x64GroupSum(w, "Y")
	w("\tADDQ\t$32, DI")
	w("\tADDQ\t$32, SI")
	w("\tSUBQ\t$8, CX")
	w("\tJMP\tcvloop8")
	w("cvloop4:")
	w("\tCMPQ\tCX, $4")
	w("\tJLT\tcvtail")
	w("\tVMOVUPS\t(SI), X0")
	w("\tVSUBPS\tX14, X0, X0")
	w("\tVMOVUPS\tX0, (DI)")
	w("\tVMULPS\tX0, X0, X0")
	x64GroupSum(w, "X")
	w("\tADDQ\t$16, DI")
	w("\tADDQ\t$16, SI")
	w("\tSUBQ\t$4, CX")
	w("\tJMP\tcvloop4")
	w("cvtail:")
	w("\tTESTQ\tCX, CX")
	w("\tJZ\tcvdone")
	w("\tVMOVSS\t(SI), X0")
	w("\tVSUBSS\tX14, X0, X0")
	w("\tVMOVSS\tX0, (DI)")
	w("\tVMULSS\tX0, X0, X0")
	w("\tVCVTSS2SD\tX0, X0, X0")
	w("\tVADDSD\tX0, X15, X15")
	w("\tADDQ\t$4, DI")
	w("\tADDQ\t$4, SI")
	w("\tSUBQ\t$1, CX")
	w("\tJMP\tcvtail")
	w("cvdone:")
	w("\tVCVTSI2SDQ\tR9, X1, X1")
	w("\tVDIVSD\tX1, X15, X15")
	w("\tVMOVSD\tX15, r0+%d(FP)", args["r0"])
	w("\tVZEROUPPER")
	w("\tRET")
	w("cvoob:")
	w("\tJMP\tovr_oob")
	return sb.String()
}
