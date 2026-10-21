package asm

import (
	"encoding/binary"
	"fmt"
	"math"
	"strings"
)

// x64QuantizeMatQ8_0_4x4Kernel is the AVX2 twin of
// a64QuantizeMatQ8_0_4x4Kernel: VMAXPS amax, nearest-even VCVTPS2DQ
// quants, the 4-wide interleave stored one 16-byte group per step.
func x64QuantizeMatQ8_0_4x4Kernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	w := func(format string, args ...any) { fmt.Fprintf(&sb, format+"\n", args...) }
	rep := func(bits uint32) string {
		b := make([]byte, 32)
		for i := 0; i < 8; i++ {
			binary.LittleEndian.PutUint32(b[4*i:], bits)
		}
		return "·" + pool.addBlob(b) + "(SB)"
	}
	cAbs := rep(0x7fffffff)
	c127 := rep(math.Float32bits(127))
	c1 := rep(math.Float32bits(1))
	args, _ := quantMatArgs(wide)
	movPtr := "MOVL"
	if wide {
		movPtr = "MOVQ"
	}
	w("// %s: quantize four f32 rows into block_q8_0x4, 4-wide interleave (VMAXPS amax, nearest-even VCVTPS2DQ quants).", sym)
	w("\t%s\tl0+%d(FP), SI", movPtr, args["l0"])
	w("\t%s\tl1+%d(FP), DI", movPtr, args["l1"])
	w("\tMOVQ\tl2+%d(FP), CX", args["l2"])
	w("\tMOVQ\tCX, DX")
	w("\tSHRQ\t$5, DX") // blocks
	w("\tJZ\tq44done")
	w("\tSHLQ\t$2, CX") // row stride bytes
	w("\tLEAQ\t(SI)(CX*4), AX")
	w("\tCMPQ\tR15, AX")
	w("\tJCS\tq44oob")
	w("\tIMUL3Q\t$%d, DX, AX", q8_0x4BlockBytes)
	w("\tADDQ\tDI, AX")
	w("\tCMPQ\tR15, AX")
	w("\tJCS\tq44oob")
	w("\tADDQ\tR14, SI")
	w("\tADDQ\tR14, DI")
	w("\tVXORPS\tX9, X9, X9") // zero
	w("\tLEAQ\t(SI)(CX*1), BX")
	w("\tLEAQ\t(BX)(CX*1), R12")
	w("\tLEAQ\t(R12)(CX*1), R13")
	w("q44blk:")
	// Pass 1: amax, d (f16) and the broadcast id per row into Y12..Y15.
	rows := []string{"SI", "BX", "R12", "R13"}
	for m := 0; m < 4; m++ {
		for i := 0; i < 4; i++ {
			w("\tVMOVUPS\t%d(%s), Y%d", 32*i, rows[m], i)
		}
		w("\tVANDPS\t%s, Y0, Y4", cAbs)
		for i := 1; i < 4; i++ {
			w("\tVANDPS\t%s, Y%d, Y5", cAbs, i)
			w("\tVMAXPS\tY5, Y4, Y4")
		}
		w("\tVEXTRACTF128\t$1, Y4, X5")
		w("\tVMAXPS\tX5, X4, X4")
		w("\tVPERMILPS\t$0x4e, X4, X5")
		w("\tVMAXPS\tX5, X4, X4")
		w("\tVPERMILPS\t$0xb1, X4, X5")
		w("\tVMAXPS\tX5, X4, X4")       // amax in lane 0
		w("\tVDIVSS\t%s, X4, X5", c127) // d = amax / 127
		w("\tVUCOMISS\tX9, X4")
		w("\tJEQ\tq44zero%d", m)
		w("\tVMOVSS\t%s, X6", c1)
		w("\tVDIVSS\tX5, X6, X8") // id = 1 / d
		w("\tJMP\tq44scale%d", m)
		w("q44zero%d:", m)
		w("\tVXORPS\tX8, X8, X8")
		w("q44scale%d:", m)
		w("\tVCVTPS2PH\t$0, X5, X5")
		w("\tVMOVD\tX5, AX")
		w("\tMOVW\tAX, %d(DI)", 2*m)
		w("\tVBROADCASTSS\tX8, X%d", 12+m)
	}
	// Pass 2: eight column groups of four rows, one 16-byte store each.
	for j := 0; j < 8; j++ {
		for m := 0; m < 4; m++ {
			w("\tVMULPS\t%d(%s), X%d, X%d", 16*j, rows[m], 12+m, m)
			w("\tVCVTPS2DQ\tX%d, X%d", m, m)
		}
		w("\tVPACKSSDW\tX1, X0, X0")
		w("\tVPACKSSDW\tX3, X2, X2")
		w("\tVPACKSSWB\tX2, X0, X0")
		w("\tVMOVDQU\tX0, %d(DI)", q8_0x4QsOff+16*j)
	}
	w("\tADDQ\t$128, SI")
	w("\tADDQ\t$128, BX")
	w("\tADDQ\t$128, R12")
	w("\tADDQ\t$128, R13")
	w("\tADDQ\t$%d, DI", q8_0x4BlockBytes)
	w("\tDECQ\tDX")
	w("\tJNZ\tq44blk")
	w("q44done:")
	w("\tVZEROUPPER")
	w("\tRET")
	w("q44oob:")
	w("\tVZEROUPPER")
	w("\tJMP\tovr_oob")
	return sb.String()
}
