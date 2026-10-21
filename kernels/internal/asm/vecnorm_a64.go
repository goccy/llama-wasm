package asm

import (
	"fmt"
	"strings"
)

// vecNormArgs is the Go ABI0 frame of the row-sum kernel
// (n i32, x ptr) -> f64, with pointers 8 bytes wide when wide.
func vecNormArgs(wide bool) (sum map[string]int, sumArgBytes int) {
	if wide {
		return map[string]int{"l0": 8, "l1": 16, "r0": 24}, 32
	}
	return map[string]int{"l0": 8, "l1": 12, "r0": 16}, 24
}

// a64VecSumKernel emits ggml_vec_sum_f64 under sym: the f64 sum of n
// floats, four lanes added in f32 as (l0+l1)+(l2+l3) and widened per
// group, the order of the C body.
func a64VecSumKernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	e := &a64VecExp{}
	e.w = func(format string, args ...any) { fmt.Fprintf(&sb, format+"\n", args...) }
	e.word = func(enc uint32, dis string) { e.w("\tWORD $0x%08x // %s", enc, dis) }
	args, _ := vecNormArgs(wide)
	movPtr := "MOVWU"
	if wide {
		movPtr = "MOVD"
	}
	w := e.w
	w("// %s: returns sum(x) (f64).", sym)
	w("\tFMOVD\tZR, F15")
	w("\tMOVW\tl0+%d(FP), R1", args["l0"])
	w("\tCMPW\t$1, R1")
	w("\tBLT\tvsdone")
	w("\t%s\tl1+%d(FP), R3", movPtr, args["l1"])
	w("\tLSL\t$2, R1, R26")
	w("\tADD\tR3, R26, R27")
	w("\tCMP\tR27, R21")
	w("\tBLO\tvsoob")
	w("\tADD\tR20, R3, R3")
	w("vsloop4:")
	w("\tCMPW\t$4, R1")
	w("\tBLT\tvstail")
	e.ldurQ(0, 3, 0)
	a64GroupSum(e, 0, 1)
	w("\tADD\t$16, R3, R3")
	w("\tSUBW\t$4, R1, R1")
	w("\tB\tvsloop4")
	w("vstail:")
	w("\tCBZW\tR1, vsdone")
	w("\tFMOVS\t(R3), F0")
	w("\tFCVTSD\tF0, F1")
	w("\tFADDD\tF1, F15, F15")
	w("\tADD\t$4, R3, R3")
	w("\tSUBW\t$1, R1, R1")
	w("\tB\tvstail")
	w("vsdone:")
	w("\tFMOVD\tF15, r0+%d(FP)", args["r0"])
	w("\tRET")
	w("vsoob:")
	w("\tB\tovr_oob")
	return sb.String()
}

// a64GroupSum adds the four f32 lanes of v<src> as (l0+l1)+(l2+l3),
// widens the result and accumulates it into F15. v<tmp> is clobbered.
func a64GroupSum(e *a64VecExp, src, tmp int) {
	e.word(0x6E20D400|uint32(src)<<16|uint32(src)<<5|uint32(tmp), fmt.Sprintf("faddp v%d.4s, v%d.4s, v%d.4s", tmp, src, src))
	e.word(0x7E30D800|uint32(tmp)<<5|uint32(tmp), fmt.Sprintf("faddp s%d, v%d.2s", tmp, tmp))
	e.w("\tFCVTSD\tF%d, F%d", tmp, tmp)
	e.w("\tFADDD\tF%d, F15, F15", tmp)
}

// a64VecCvarKernel emits ggml_vec_cvar_f32 under sym: y = x - mean,
// returns sum(y*y)/n (f64), the squares reduced per group of four as
// a64VecSumKernel does.
func a64VecCvarKernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	e := &a64VecExp{}
	e.w = func(format string, args ...any) { fmt.Fprintf(&sb, format+"\n", args...) }
	e.word = func(enc uint32, dis string) { e.w("\tWORD $0x%08x // %s", enc, dis) }
	args, _, _, _ := vecExpArgs(wide)
	movPtr := "MOVWU"
	if wide {
		movPtr = "MOVD"
	}
	w := e.w
	w("// %s: y = x - mean, returns sum(y*y)/n (f64).", sym)
	w("\tFMOVD\tZR, F15")
	w("\tMOVW\tl0+%d(FP), R1", args["l0"])
	w("\tCMPW\t$1, R1")
	w("\tBLT\tcvdone")
	w("\tMOVW\tR1, R5")
	w("\t%s\tl1+%d(FP), R2", movPtr, args["l1"])
	w("\t%s\tl2+%d(FP), R3", movPtr, args["l2"])
	w("\tLSL\t$2, R1, R26")
	w("\tADD\tR2, R26, R27")
	w("\tCMP\tR27, R21")
	w("\tBLO\tcvoob")
	w("\tADD\tR3, R26, R27")
	w("\tCMP\tR27, R21")
	w("\tBLO\tcvoob")
	w("\tADD\tR20, R2, R2")
	w("\tADD\tR20, R3, R3")
	w("\tFMOVS\tl3+%d(FP), F14", args["l3"])
	e.dupLane(14, 14, 0)
	w("cvloop4:")
	w("\tCMPW\t$4, R1")
	w("\tBLT\tcvtail")
	e.ldurQ(0, 3, 0)
	e.fsubV(0, 0, 14)
	e.sturQ(0, 2, 0)
	e.fmulV(0, 0, 0)
	a64GroupSum(e, 0, 1)
	w("\tADD\t$16, R2, R2")
	w("\tADD\t$16, R3, R3")
	w("\tSUBW\t$4, R1, R1")
	w("\tB\tcvloop4")
	w("cvtail:")
	w("\tCBZW\tR1, cvdone")
	w("\tFMOVS\t(R3), F0")
	w("\tFSUBS\tF14, F0, F0")
	w("\tFMOVS\tF0, (R2)")
	w("\tFMULS\tF0, F0, F0")
	w("\tFCVTSD\tF0, F1")
	w("\tFADDD\tF1, F15, F15")
	w("\tADD\t$4, R2, R2")
	w("\tADD\t$4, R3, R3")
	w("\tSUBW\t$1, R1, R1")
	w("\tB\tcvtail")
	w("cvdone:")
	w("\tSCVTFWD\tR5, F1")
	w("\tFDIVD\tF1, F15, F15")
	w("\tFMOVD\tF15, r0+%d(FP)", args["r0"])
	w("\tRET")
	w("cvoob:")
	w("\tB\tovr_oob")
	return sb.String()
}
