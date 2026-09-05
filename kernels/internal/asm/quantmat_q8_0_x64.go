package asm

import (
	"encoding/binary"
	"fmt"
	"math"
	"strings"
)

// x64QuantizeMatQ8_0_4x8Kernel: the AVX2 twin of
// a64QuantizeMatQ8_0_4x8Kernel. Quants round to nearest even
// (VCVTPS2DQ under the default MXCSR), matching quantize_row_q8_0 and
// the native SIMD quantizers; see the arm64 twin for why.
//
// Registers: SI x (block, advancing), DI vy (block, advancing), CX row
// stride bytes, DX blocks left, R8 rows left, R9 row's block start, R10
// vy + 8r, R11 vy + 2r, AX scratch. Y0..Y3 the row's floats, Y4..Y7
// scratch, Y8 id broadcast.
func x64QuantizeMatQ8_0_4x8Kernel(sym string, pool *ConstPool, wide bool) string {
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
	w("// %s: quantize four f32 rows into block_q8_0x4 (VMAXPS amax, nearest-even VCVTPS2DQ quants).", sym)
	w("\t%s\tl0+%d(FP), SI", movPtr, args["l0"])
	w("\t%s\tl1+%d(FP), DI", movPtr, args["l1"])
	w("\tMOVQ\tl2+%d(FP), CX", args["l2"])
	w("\tMOVQ\tCX, DX")
	w("\tSHRQ\t$5, DX") // blocks
	w("\tJZ\tq8mdone")
	w("\tSHLQ\t$2, CX") // row stride bytes
	w("\tLEAQ\t(SI)(CX*4), AX")
	w("\tCMPQ\tR15, AX")
	w("\tJCS\tq8moob")
	w("\tIMUL3Q\t$%d, DX, AX", q8_0x4BlockBytes)
	w("\tADDQ\tDI, AX")
	w("\tCMPQ\tR15, AX")
	w("\tJCS\tq8moob")
	w("\tADDQ\tR14, SI")
	w("\tADDQ\tR14, DI")
	w("\tVXORPS\tX9, X9, X9") // zero
	w("q8mblk:")
	w("\tMOVQ\tSI, R9")
	w("\tMOVQ\tDI, R10")
	w("\tMOVQ\tDI, R11")
	w("\tMOVL\t$4, R8")
	w("q8mrow:")
	for i := 0; i < 4; i++ {
		w("\tVMOVUPS\t%d(R9), Y%d", 32*i, i)
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
	w("\tJEQ\tq8mzero")
	w("\tVMOVSS\t%s, X6", c1)
	w("\tVDIVSS\tX5, X6, X8") // id = 1 / d
	w("\tJMP\tq8mscale")
	w("q8mzero:")
	w("\tVXORPS\tX8, X8, X8")
	w("q8mscale:")
	w("\tVCVTPS2PH\t$0, X5, X5")
	w("\tVMOVD\tX5, AX")
	w("\tMOVW\tAX, (R11)")
	w("\tVBROADCASTSS\tX8, Y8")
	for k := 0; k < 4; k++ {
		w("\tVMULPS\tY8, Y%d, Y4", k)
		w("\tVCVTPS2DQ\tY4, Y4")
		w("\tVEXTRACTI128\t$1, Y4, X5")
		w("\tVPACKSSDW\tX5, X4, X4")
		w("\tVPACKSSWB\tX4, X4, X4")
		w("\tVMOVQ\tX4, %d(R10)", q8_0x4QsOff+32*k)
	}
	w("\tADDQ\tCX, R9")
	w("\tADDQ\t$8, R10")
	w("\tADDQ\t$2, R11")
	w("\tDECL\tR8")
	w("\tJNZ\tq8mrow")
	w("\tADDQ\t$128, SI")
	w("\tADDQ\t$%d, DI", q8_0x4BlockBytes)
	w("\tDECQ\tDX")
	w("\tJNZ\tq8mblk")
	w("q8mdone:")
	w("\tVZEROUPPER")
	w("\tRET")
	w("q8moob:")
	w("\tVZEROUPPER")
	w("\tJMP\tovr_oob")
	return sb.String()
}
