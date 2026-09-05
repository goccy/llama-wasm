package asm

import (
	"encoding/binary"
	"fmt"
	"math"
	"strings"
)

// x64QuantizeMatQ8K4x8Kernel: the AVX2 twin of
// a64QuantizeMatQ8K4x8Kernel (same arithmetic; VCVTPS2DQ rounds to
// nearest even under the default MXCSR, like FCVTNS).
//
// Registers: SI x (block, advancing), DI vy (block, advancing), CX row
// stride bytes, DX blocks left, R8 rows left, R9 row's block start,
// R10 vy + 8r, R11 vy + 4r, R12 loop counter, AX scratch. Y0 max, Y1
// min, Y7 iscale broadcast, X2..X6 and X8..X13 scratch.
func x64QuantizeMatQ8K4x8Kernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	w := func(format string, args ...any) { fmt.Fprintf(&sb, format+"\n", args...) }
	f32 := func(v float32) string {
		b := make([]byte, 4)
		binary.LittleEndian.PutUint32(b, math.Float32bits(v))
		return "·" + pool.addBlob(b) + "(SB)"
	}
	c127, c1 := f32(127), f32(1)
	ones := make([]byte, 16)
	for i := 0; i < 8; i++ {
		ones[2*i] = 1
	}
	cOnes := "·" + pool.addBlob(ones) + "(SB)"
	args, _ := quantMatArgs(wide)
	movPtr := "MOVL"
	if wide {
		movPtr = "MOVQ"
	}
	w("// %s: quantize four f32 rows into block_q8_Kx4 (VMAXPS/VMINPS max, VCVTPS2DQ quants, VPMADDWD chunk sums).", sym)
	w("\t%s\tl0+%d(FP), SI", movPtr, args["l0"])
	w("\t%s\tl1+%d(FP), DI", movPtr, args["l1"])
	w("\tMOVQ\tl2+%d(FP), CX", args["l2"])
	w("\tMOVQ\tCX, DX")
	w("\tSHRQ\t$8, DX") // blocks
	w("\tJZ\tqmdone")
	w("\tSHLQ\t$2, CX") // row stride bytes
	// x + 4 rows * stride, vy + nb * 1168 must fit.
	w("\tLEAQ\t(SI)(CX*4), AX")
	w("\tCMPQ\tR15, AX")
	w("\tJCS\tqmoob")
	w("\tIMUL3Q\t$%d, DX, AX", q8Kx4BlockBytes)
	w("\tADDQ\tDI, AX")
	w("\tCMPQ\tR15, AX")
	w("\tJCS\tqmoob")
	w("\tADDQ\tR14, SI")
	w("\tADDQ\tR14, DI")
	w("\tVXORPS\tX14, X14, X14") // zero
	w("qmblk:")
	w("\tMOVQ\tSI, R9")
	w("\tMOVQ\tDI, R10")
	w("\tMOVQ\tDI, R11")
	w("\tMOVL\t$4, R8")
	w("qmrow:")
	// --- pass 1: max and min over the 256 elements (32 ymm).
	w("\tVMOVUPS\t(R9), Y0")
	w("\tVMOVAPS\tY0, Y1")
	for i := 1; i < 32; i++ {
		w("\tVMOVUPS\t%d(R9), Y2", 32*i)
		w("\tVMAXPS\tY2, Y0, Y0")
		w("\tVMINPS\tY2, Y1, Y1")
	}
	for _, r := range []struct {
		op string
		v  int
	}{{"VMAXPS", 0}, {"VMINPS", 1}} {
		w("\tVEXTRACTF128\t$1, Y%d, X2", r.v)
		w("\t%s\tX2, X%d, X%d", r.op, r.v, r.v)
		w("\tVPERMILPS\t$0x4e, X%d, X2", r.v)
		w("\t%s\tX2, X%d, X%d", r.op, r.v, r.v)
		w("\tVPERMILPS\t$0xb1, X%d, X2", r.v)
		w("\t%s\tX2, X%d, X%d", r.op, r.v, r.v)
	}
	// max = (maxv >= -minv) ? maxv : minv; amax = max(maxv, -minv)
	w("\tVSUBSS\tX1, X14, X6")
	w("\tVMAXSS\tX6, X0, X3")
	w("\tVMOVAPS\tX0, X2")
	w("\tVUCOMISS\tX6, X0")
	w("\tJAE\tqmsel")
	w("\tVMOVAPS\tX1, X2")
	w("qmsel:")
	w("\tVUCOMISS\tX14, X3")
	w("\tJEQ\tqmzero")
	w("\tVMOVSS\t%s, X4", c127)
	w("\tVDIVSS\tX2, X4, X7")  // 127 / max
	w("\tVSUBSS\tX7, X14, X7") // iscale
	w("\tVMOVSS\t%s, X4", c1)
	w("\tVDIVSS\tX7, X4, X3") // d = 1 / iscale
	w("\tJMP\tqmscale")
	w("qmzero:")
	w("\tVXORPS\tX7, X7, X7")
	w("\tVXORPS\tX3, X3, X3")
	w("qmscale:")
	w("\tVMOVSS\tX3, (R11)")
	w("\tVBROADCASTSS\tX7, Y7")
	// --- pass 2: quantize the 32 groups of eight; chunk sums per 16.
	for g := 0; g < 32; g++ {
		w("\tVMULPS\t%d(R9), Y7, Y8", 32*g)
		w("\tVCVTPS2DQ\tY8, Y8")
		w("\tVEXTRACTI128\t$1, Y8, X9")
		w("\tVPACKSSDW\tX9, X8, X8")
		if g%2 == 0 {
			w("\tVMOVDQA\tX8, X12")
		} else {
			w("\tVPADDW\tX8, X12, X12")
			w("\tVPMADDWD\t%s, X12, X13", cOnes)
			w("\tVPHADDD\tX13, X13, X13")
			w("\tVPHADDD\tX13, X13, X13")
			w("\tVMOVD\tX13, AX")
			c := g / 2
			w("\tMOVW\tAX, %d(R10)", q8Kx4BsumsOff+32*(c/4)+2*(c%4))
		}
		w("\tVPACKSSWB\tX8, X8, X8")
		w("\tVMOVQ\tX8, %d(R10)", q8Kx4QsOff+32*g)
	}
	w("\tADDQ\tCX, R9")
	w("\tADDQ\t$8, R10")
	w("\tADDQ\t$4, R11")
	w("\tDECL\tR8")
	w("\tJNZ\tqmrow")
	w("\tADDQ\t$1024, SI")
	w("\tADDQ\t$%d, DI", q8Kx4BlockBytes)
	w("\tDECQ\tDX")
	w("\tJNZ\tqmblk")
	w("qmdone:")
	w("\tVZEROUPPER")
	w("\tRET")
	w("qmoob:")
	w("\tVZEROUPPER")
	w("\tJMP\tovr_oob")
	return sb.String()
}
