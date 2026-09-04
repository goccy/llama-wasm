package asm

import (
	"fmt"
	"strings"
)

// x64FlashAttnKernel: the AVX2 twin of a64FlashAttnKernel (same args
// struct, same arithmetic: f32 K.Q via VCVTPH2PS + FMA, the online
// softmax with the polynomial expf of the soft_max kernel, the F16 V
// accumulate into the f32 VKQ row). FastMath only.
//
// Registers: SI K row (advancing), DI V row (advancing), R8 nbk1, R9
// nbv1, R10 mask element (advancing, 0 when no mask), R11 positions
// left, R12 SM, R13 VKQ32, BX Q_q; AX/CX/DX loop scratch. X12 S, X13 M,
// Y14 vs, Y15 ms (broadcast); Y0..Y11 scratch (the exp routine
// clobbers X1..X11). The frame keeps what does not fit: DK, DV, the
// 16-wide chunk counts and 8-wide tail flags, scale, slope and mv.
const (
	x64faDK    = 0
	x64faDV    = 4
	x64faDK16  = 8
	x64faDK8   = 12
	x64faDV16  = 16
	x64faDV8   = 20
	x64faScale = 24
	x64faSlope = 28
	x64faMv    = 32
	x64FAFrame = 40
)

func x64FlashAttnKernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	w := func(format string, args ...any) { fmt.Fprintf(&sb, format+"\n", args...) }
	e := newX64VecExp(w, pool)
	negInf := "·" + pool.addBlob([]byte{0, 0, 0x80, 0xff}) + "(SB)"
	args, _ := flashAttnArgs(wide)
	movPtr := "MOVL"
	if wide {
		movPtr = "MOVQ"
	}
	w("// %s: single-query flash-attention KV loop (F16 K/V, f32 VKQ), exp in registers.", sym)
	w("\t%s\tl0+%d(FP), AX", movPtr, args["l0"])
	w("\tLEAQ\t%d(AX), CX", faArgSize)
	w("\tCMPQ\tR15, CX")
	w("\tJCS\tfaoob")
	w("\tADDQ\tR14, AX")
	// DK, DV and their chunk counts (multiples of 8).
	for _, d := range []struct{ arg, n, c16, c8 int }{{faArgDK, x64faDK, x64faDK16, x64faDK8}, {faArgDV, x64faDV, x64faDV16, x64faDV8}} {
		w("\tMOVL\t%d(AX), CX", d.arg)
		w("\tMOVL\tCX, %d(SP)", d.n)
		w("\tMOVL\tCX, DX")
		w("\tSHRL\t$4, DX")
		w("\tMOVL\tDX, %d(SP)", d.c16)
		w("\tSHRL\t$3, CX")
		w("\tANDL\t$1, CX")
		w("\tMOVL\tCX, %d(SP)", d.c8)
	}
	w("\tVMOVSS\t%d(AX), X0", faArgScale)
	w("\tVMOVSS\tX0, %d(SP)", x64faScale)
	w("\tVMOVSS\t%d(AX), X0", faArgSlope)
	w("\tVMOVSS\tX0, %d(SP)", x64faSlope)
	w("\tMOVQ\t%d(AX), CX", faArgQ)
	w("\tMOVQ\t%d(AX), SI", faArgK)
	w("\tMOVQ\t%d(AX), R8", faArgNbk)
	w("\tMOVQ\t%d(AX), DI", faArgV)
	w("\tMOVQ\t%d(AX), R9", faArgNbv)
	w("\tMOVQ\t%d(AX), R10", faArgMask)
	w("\tMOVQ\t%d(AX), R12", faArgSM)
	w("\tMOVQ\t%d(AX), R13", faArgVKQ)
	w("\tMOVQ\t%d(AX), R11", faArgStart)
	w("\tMOVQ\t%d(AX), AX", faArgEnd)
	// SM + 8, VKQ + 4*DV, Q + 2*DK
	w("\tLEAQ\t8(R12), BX")
	w("\tCMPQ\tR15, BX")
	w("\tJCS\tfaoob")
	w("\tMOVL\t%d(SP), DX", x64faDV)
	w("\tLEAQ\t(R13)(DX*4), BX")
	w("\tCMPQ\tR15, BX")
	w("\tJCS\tfaoob")
	w("\tMOVL\t%d(SP), DX", x64faDK)
	w("\tLEAQ\t(CX)(DX*2), BX")
	w("\tCMPQ\tR15, BX")
	w("\tJCS\tfaoob")
	// positions = ic_end - ic_start; nothing to do when <= 0.
	w("\tSUBQ\tR11, AX")
	w("\tJLE\tfaret")
	// K/V rows: base + ic_start*nb .. base + (ic_end-1)*nb + 2*D must fit.
	w("\tMOVQ\tR11, BX")
	w("\tIMULQ\tR8, BX")
	w("\tADDQ\tBX, SI")
	w("\tMOVQ\tR11, BX")
	w("\tIMULQ\tR9, BX")
	w("\tADDQ\tBX, DI")
	w("\tLEAQ\t-1(AX), BX")
	w("\tIMULQ\tR8, BX")
	w("\tADDQ\tSI, BX")
	w("\tLEAQ\t(BX)(DX*2), BX") // DX = DK
	w("\tCMPQ\tR15, BX")
	w("\tJCS\tfaoob")
	w("\tLEAQ\t-1(AX), BX")
	w("\tIMULQ\tR9, BX")
	w("\tADDQ\tDI, BX")
	w("\tMOVL\t%d(SP), DX", x64faDV)
	w("\tLEAQ\t(BX)(DX*2), BX")
	w("\tCMPQ\tR15, BX")
	w("\tJCS\tfaoob")
	w("\tTESTQ\tR10, R10")
	w("\tJZ\tfamaskok")
	w("\tLEAQ\t(R10)(R11*2), R10") // mp + ic_start (elements)
	w("\tLEAQ\t(R10)(AX*2), BX")
	w("\tCMPQ\tR15, BX")
	w("\tJCS\tfaoob")
	w("\tADDQ\tR14, R10")
	w("famaskok:")
	w("\tADDQ\tR14, SI")
	w("\tADDQ\tR14, DI")
	w("\tADDQ\tR14, R12")
	w("\tADDQ\tR14, R13")
	w("\tLEAQ\t(CX)(R14*1), BX") // Q_q
	w("\tMOVQ\tAX, R11")         // positions
	w("\tVMOVSS\t(R12), X12")    // S
	w("\tVMOVSS\t4(R12), X13")   // M

	w("fapos:")
	// --- mask value mv: slope * f16(mp[ic]); -inf skips the position.
	w("\tVXORPS\tX0, X0, X0")
	w("\tVMOVSS\tX0, %d(SP)", x64faMv)
	w("\tTESTQ\tR10, R10")
	w("\tJZ\tfadot")
	w("\tMOVWLZX\t(R10), AX")
	w("\tADDQ\t$2, R10")
	w("\tVMOVD\tAX, X0")
	w("\tVCVTPH2PS\tX0, X0")
	w("\tVMULSS\t%d(SP), X0, X0", x64faSlope)
	w("\tVMOVSS\tX0, %d(SP)", x64faMv)
	w("\tVUCOMISS\t%s, X0", negInf)
	w("\tJP\tfadot")
	w("\tJE\tfaskip")
	w("fadot:")
	// --- s = K.Q (f16 x f16 -> f32): DX = K row, AX = Q, CX = 16-wide chunks.
	w("\tMOVQ\tSI, DX")
	w("\tMOVQ\tBX, AX")
	w("\tVXORPS\tY0, Y0, Y0")
	w("\tVXORPS\tY1, Y1, Y1")
	w("\tMOVL\t%d(SP), CX", x64faDK16)
	w("\tTESTL\tCX, CX")
	w("\tJZ\tfadottail")
	w("fadotloop:")
	w("\tVCVTPH2PS\t(DX), Y2")
	w("\tVCVTPH2PS\t16(DX), Y3")
	w("\tVCVTPH2PS\t(AX), Y4")
	w("\tVCVTPH2PS\t16(AX), Y5")
	w("\tVFMADD231PS\tY4, Y2, Y0")
	w("\tVFMADD231PS\tY5, Y3, Y1")
	w("\tADDQ\t$32, DX")
	w("\tADDQ\t$32, AX")
	w("\tDECL\tCX")
	w("\tJNZ\tfadotloop")
	w("fadottail:")
	w("\tCMPL\t%d(SP), $0", x64faDK8)
	w("\tJEQ\tfadotdone")
	w("\tVCVTPH2PS\t(DX), Y2")
	w("\tVCVTPH2PS\t(AX), Y4")
	w("\tVFMADD231PS\tY4, Y2, Y0")
	w("fadotdone:")
	w("\tVADDPS\tY1, Y0, Y0")
	w("\tVEXTRACTF128\t$1, Y0, X1")
	w("\tVADDPS\tX1, X0, X0")
	w("\tVHADDPS\tX0, X0, X0")
	w("\tVHADDPS\tX0, X0, X0")
	// s = s*scale + mv
	w("\tVMOVSS\t%d(SP), X1", x64faScale)
	w("\tVFMADD213SS\t%d(SP), X1, X0", x64faMv)
	// --- online softmax.
	w("\tVUCOMISS\tX13, X0")
	w("\tJA\tfanewmax")
	// vs = exp(s - M); ms = 1
	w("\tVSUBSS\tX13, X0, X0")
	e.exp("X", 0, 0)
	w("\tVBROADCASTSS\tX0, Y14")
	w("\tVBROADCASTSS\t%s, Y15", e.sym("one"))
	w("\tJMP\tfamad")
	w("fanewmax:")
	// ms = exp(Mold - s); M = s; VKQ *= ms; vs = 1
	w("\tVSUBSS\tX0, X13, X1")
	w("\tVMOVAPS\tX0, X13")
	w("\tVMOVAPS\tX1, X0")
	e.exp("X", 0, 0)
	w("\tVBROADCASTSS\tX0, Y15")
	w("\tVBROADCASTSS\t%s, Y14", e.sym("one"))
	w("\tMOVQ\tR13, DX")
	w("\tMOVL\t%d(SP), CX", x64faDV16)
	w("\tTESTL\tCX, CX")
	w("\tJZ\tfascaletail")
	w("fascale:")
	w("\tVMULPS\t(DX), Y15, Y0")
	w("\tVMULPS\t32(DX), Y15, Y1")
	w("\tVMOVUPS\tY0, (DX)")
	w("\tVMOVUPS\tY1, 32(DX)")
	w("\tADDQ\t$64, DX")
	w("\tDECL\tCX")
	w("\tJNZ\tfascale")
	w("fascaletail:")
	w("\tCMPL\t%d(SP), $0", x64faDV8)
	w("\tJEQ\tfamad")
	w("\tVMULPS\t(DX), Y15, Y0")
	w("\tVMOVUPS\tY0, (DX)")
	w("famad:")
	// --- VKQ += vs * V (f16 -> f32): AX = V row, DX = VKQ, CX = chunks.
	w("\tMOVQ\tDI, AX")
	w("\tMOVQ\tR13, DX")
	w("\tMOVL\t%d(SP), CX", x64faDV16)
	w("\tTESTL\tCX, CX")
	w("\tJZ\tfamadtail")
	w("famadloop:")
	w("\tVCVTPH2PS\t(AX), Y2")
	w("\tVCVTPH2PS\t16(AX), Y3")
	w("\tVMOVUPS\t(DX), Y0")
	w("\tVMOVUPS\t32(DX), Y1")
	w("\tVFMADD231PS\tY2, Y14, Y0")
	w("\tVFMADD231PS\tY3, Y14, Y1")
	w("\tVMOVUPS\tY0, (DX)")
	w("\tVMOVUPS\tY1, 32(DX)")
	w("\tADDQ\t$32, AX")
	w("\tADDQ\t$64, DX")
	w("\tDECL\tCX")
	w("\tJNZ\tfamadloop")
	w("famadtail:")
	w("\tCMPL\t%d(SP), $0", x64faDV8)
	w("\tJEQ\tfamaddone")
	w("\tVCVTPH2PS\t(AX), Y2")
	w("\tVMOVUPS\t(DX), Y0")
	w("\tVFMADD231PS\tY2, Y14, Y0")
	w("\tVMOVUPS\tY0, (DX)")
	w("famaddone:")
	// S = S*ms + vs
	w("\tVFMADD213SS\tX14, X15, X12")
	w("faskip:")
	w("\tADDQ\tR8, SI")
	w("\tADDQ\tR9, DI")
	w("\tDECQ\tR11")
	w("\tJNZ\tfapos")
	w("fadone:")
	w("\tVMOVSS\tX12, (R12)")
	w("\tVMOVSS\tX13, 4(R12)")
	w("faret:")
	w("\tVZEROUPPER")
	w("\tRET")
	w("faoob:")
	w("\tVZEROUPPER")
	w("\tJMP\tovr_oob")
	return sb.String()
}
