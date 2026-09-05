package asm

import (
	"fmt"
	"strings"
)

// x64FlashAttnKernel: the AVX2 body of the single-query flash-attention
// KV loop (same args struct and arithmetic contract as the arm64 bodies;
// f32 accumulation like the NEON one). Positions go in blocks of eight:
//
//   - K.Q per position is VCVTPH2PS + FMA over eight-element chunks
//     (f16 K and Q widened as they stream, no residency needed);
//   - the block's eight scores take one vectorized exp instead of one
//     per position; masked (-inf) positions and the lanes past the
//     block end flush through exp(-200) = 0; a block that raises the
//     running max replays the per-position recurrence instead, so the
//     numerics never depend on how positions fall into blocks;
//   - VKQ (the caller's f32 buffer) accumulates chunk by chunk: each
//     32-byte chunk is loaded once, receives the block's eight positions
//     (p_i broadcast in Y0..Y7, V_i widened on the fly) and is stored
//     once.
//
// DK and DV are multiples of 8. FastMath only.
//
// Registers: SI K row (block start), DI V row (block start), R8 nbk1,
// R9 nbv1, R10 mask element (0 without a mask), R11 positions left, R12
// SM, R13 VKQ32, BX Q_q; AX/CX/DX scratch. X12 S, X13 M; Y14/Y15
// scratch outside the exp routine's Y1..Y11; Y0..Y7 the block's weights
// during the V accumulate. Frame: 0 scores (8 f32) | 32 weights (8
// f32) | 64 DK | 68 DV | 72 DK/8 | 76 DV/8 | 80 scale | 84 slope | 88
// block size | 92 chunk counter | 96 V row (exact path) | 104 position
// index (exact path).
const (
	x64faScores = 0
	x64faP      = 32
	x64faDK     = 64
	x64faDV     = 68
	x64faDK8    = 72
	x64faDV8    = 76
	x64faScale  = 80
	x64faSlope  = 84
	x64faNblk   = 88
	x64faCnt    = 92
	x64faVrow   = 96 // exact path: V row of the current position
	x64faIdx    = 104
	x64FAFrame  = 112
)

func x64FlashAttnKernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	w := func(format string, args ...any) { fmt.Fprintf(&sb, format+"\n", args...) }
	e := newX64VecExp(w, pool)
	rep := func(bits uint32) string {
		b := make([]byte, 32)
		for i := 0; i < 8; i++ {
			b[4*i], b[4*i+1], b[4*i+2], b[4*i+3] = byte(bits), byte(bits>>8), byte(bits>>16), byte(bits>>24)
		}
		return "·" + pool.addBlob(b) + "(SB)"
	}
	negInf := rep(0xff800000)
	neg200 := rep(0xc3480000)
	one := rep(0x3f800000)
	args, _ := flashAttnArgs(wide)
	movPtr := "MOVL"
	if wide {
		movPtr = "MOVQ"
	}
	hmax := func() { // X0 = max of the eight lanes of Y0
		w("\tVEXTRACTF128\t$1, Y0, X1")
		w("\tVMAXPS\tX1, X0, X0")
		w("\tVPERMILPS\t$0x4e, X0, X1")
		w("\tVMAXPS\tX1, X0, X0")
		w("\tVPERMILPS\t$0xb1, X0, X1")
		w("\tVMAXPS\tX1, X0, X0")
	}
	w("// %s: single-query flash-attention KV loop (F16 K/V, f32 VKQ), blocks of eight positions, exp in registers.", sym)
	w("\t%s\tl0+%d(FP), AX", movPtr, args["l0"])
	w("\tLEAQ\t%d(AX), CX", faArgSize)
	w("\tCMPQ\tR15, CX")
	w("\tJCS\tfaoob")
	w("\tADDQ\tR14, AX")
	for _, d := range []struct{ arg, n, c8 int }{{faArgDK, x64faDK, x64faDK8}, {faArgDV, x64faDV, x64faDV8}} {
		w("\tMOVL\t%d(AX), CX", d.arg)
		w("\tMOVL\tCX, %d(SP)", d.n)
		w("\tSHRL\t$3, CX")
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

	w("fablk:")
	// block size = min(8, positions left)
	w("\tMOVL\t$8, AX")
	w("\tCMPQ\tR11, $8")
	w("\tJGE\tfanblk")
	w("\tMOVL\tR11, AX")
	w("fanblk:")
	w("\tMOVL\tAX, %d(SP)", x64faNblk)
	w("\tVMOVUPS\t%s, Y0", negInf)
	w("\tVMOVUPS\tY0, %d(SP)", x64faScores)
	// --- scores: s_i = (K_i . Q) * scale + mv_i, mv_i = slope * f16(mp[i])
	for i := 0; i < 8; i++ {
		if i > 0 {
			w("\tCMPL\t%d(SP), $%d", x64faNblk, i)
			w("\tJLE\tfascored")
		}
		if i == 0 {
			w("\tMOVQ\tSI, AX")
		} else {
			w("\tIMUL3Q\t$%d, R8, AX", i)
			w("\tADDQ\tSI, AX")
		}
		w("\tMOVQ\tBX, CX")
		w("\tMOVL\t%d(SP), DX", x64faDK8)
		w("\tVXORPS\tY0, Y0, Y0")
		w("fadot%d:", i)
		w("\tVCVTPH2PS\t(AX), Y1")
		w("\tVCVTPH2PS\t(CX), Y2")
		w("\tVFMADD231PS\tY2, Y1, Y0")
		w("\tADDQ\t$16, AX")
		w("\tADDQ\t$16, CX")
		w("\tDECL\tDX")
		w("\tJNZ\tfadot%d", i)
		w("\tVEXTRACTF128\t$1, Y0, X1")
		w("\tVADDPS\tX1, X0, X0")
		w("\tVHADDPS\tX0, X0, X0")
		w("\tVHADDPS\tX0, X0, X0")
		w("\tVXORPS\tX1, X1, X1")
		w("\tTESTQ\tR10, R10")
		w("\tJZ\tfanomask%d", i)
		w("\tMOVWLZX\t%d(R10), AX", 2*i)
		w("\tVMOVD\tAX, X1")
		w("\tVCVTPH2PS\tX1, X1")
		w("\tVMULSS\t%d(SP), X1, X1", x64faSlope)
		w("fanomask%d:", i)
		w("\tVMOVSS\t%d(SP), X2", x64faScale)
		w("\tVFMADD213SS\tX1, X2, X0") // X0 = X2*X0 + X1
		w("\tVMOVSS\tX0, %d(SP)", x64faScores+4*i)
	}
	w("fascored:")
	// --- block max; all -inf (every position masked) skips the block
	w("\tVMOVUPS\t%d(SP), Y0", x64faScores)
	hmax()
	w("\tVUCOMISS\t%s, X0", negInf)
	w("\tJEQ\tfaadvance")
	// a block holding a new max takes the per-position path
	w("\tVUCOMISS\tX13, X0")
	w("\tJA\tfaexact")
	// --- fast path (no new max): p = exp(max(s - M, -200)); S += p_i in
	// position order (a zero lane leaves S unchanged)
	w("\tVMOVUPS\t%d(SP), Y14", x64faScores)
	w("\tVBROADCASTSS\tX13, Y15")
	w("\tVSUBPS\tY15, Y14, Y14")
	w("\tVMAXPS\t%s, Y14, Y14", neg200)
	e.exp("Y", 14, 14)
	w("\tVMOVUPS\tY14, %d(SP)", x64faP)
	for i := 0; i < 8; i++ {
		w("\tVADDSS\t%d(SP), X12, X12", x64faP+4*i)
	}
	// --- VKQ[c] += sum_i p_i * V_i[c], chunk by chunk, positions in order
	for i := 0; i < 8; i++ {
		w("\tVBROADCASTSS\t%d(SP), Y%d", x64faP+4*i, i)
	}
	w("\tMOVQ\tR13, AX")
	w("\tMOVQ\tDI, CX")
	w("\tMOVL\t%d(SP), DX", x64faDV8)
	w("\tMOVL\tDX, %d(SP)", x64faCnt)
	w("fachunk:")
	w("\tVMOVUPS\t(AX), Y8")
	w("\tMOVQ\tCX, DX")
	for i := 0; i < 8; i++ {
		if i > 0 {
			w("\tCMPL\t%d(SP), $%d", x64faNblk, i)
			w("\tJLE\tfachunkdone")
		}
		w("\tVCVTPH2PS\t(DX), Y9")
		w("\tVFMADD231PS\tY%d, Y9, Y8", i)
		if i < 7 {
			w("\tADDQ\tR9, DX")
		}
	}
	w("fachunkdone:")
	w("\tVMOVUPS\tY8, (AX)")
	w("\tADDQ\t$32, AX")
	w("\tADDQ\t$16, CX")
	w("\tDECL\t%d(SP)", x64faCnt)
	w("\tJNZ\tfachunk")
	w("\tJMP\tfaadvance")
	// --- exact path: the per-position recurrence over the block's
	// scores. A masked score is skipped; a new max rescales S and VKQ by
	// ms = exp(M - s) and contributes with weight 1; otherwise the weight
	// is exp(s - M). X14 the weight, Y14 its broadcast.
	w("faexact:")
	w("\tMOVQ\tDI, %d(SP)", x64faVrow)
	w("\tMOVL\t$0, %d(SP)", x64faIdx)
	w("fapos:")
	w("\tMOVL\t%d(SP), AX", x64faIdx)
	w("\tLEAQ\t%d(SP), CX", x64faScores)
	w("\tVMOVSS\t(CX)(AX*4), X0")
	w("\tVUCOMISS\t%s, X0", negInf)
	w("\tJEQ\tfaposnext")
	w("\tVUCOMISS\tX13, X0")
	w("\tJBE\tfaposkeep")
	// new max: ms = exp(max(M - s, -200)); S *= ms; VKQ *= ms; M = s
	w("\tVSUBSS\tX0, X13, X14")
	w("\tVMAXSS\t%s, X14, X14", neg200)
	e.exp("X", 14, 14)
	w("\tVMULSS\tX14, X12, X12")
	w("\tVBROADCASTSS\tX14, Y14")
	w("\tMOVQ\tR13, AX")
	w("\tMOVL\t%d(SP), CX", x64faDV8)
	w("faposscale:")
	w("\tVMULPS\t(AX), Y14, Y1")
	w("\tVMOVUPS\tY1, (AX)")
	w("\tADDQ\t$32, AX")
	w("\tDECL\tCX")
	w("\tJNZ\tfaposscale")
	w("\tVMOVAPS\tX0, X13")
	w("\tVMOVSS\t%s, X14", one) // vs = 1
	w("\tJMP\tfaposacc")
	w("faposkeep:")
	// vs = exp(max(s - M, -200))
	w("\tVSUBSS\tX13, X0, X14")
	w("\tVMAXSS\t%s, X14, X14", neg200)
	e.exp("X", 14, 14)
	w("faposacc:")
	// S += vs; VKQ += vs * V_i
	w("\tVADDSS\tX14, X12, X12")
	w("\tVBROADCASTSS\tX14, Y14")
	w("\tMOVQ\tR13, AX")
	w("\tMOVQ\t%d(SP), DX", x64faVrow)
	w("\tMOVL\t%d(SP), CX", x64faDV8)
	w("faposmad:")
	w("\tVCVTPH2PS\t(DX), Y9")
	w("\tVMOVUPS\t(AX), Y8")
	w("\tVFMADD231PS\tY14, Y9, Y8")
	w("\tVMOVUPS\tY8, (AX)")
	w("\tADDQ\t$32, AX")
	w("\tADDQ\t$16, DX")
	w("\tDECL\tCX")
	w("\tJNZ\tfaposmad")
	w("faposnext:")
	w("\tMOVQ\t%d(SP), AX", x64faVrow)
	w("\tADDQ\tR9, AX")
	w("\tMOVQ\tAX, %d(SP)", x64faVrow)
	w("\tINCL\t%d(SP)", x64faIdx)
	w("\tMOVL\t%d(SP), AX", x64faIdx)
	w("\tCMPL\tAX, %d(SP)", x64faNblk)
	w("\tJLT\tfapos")
	w("faadvance:")
	w("\tMOVL\t%d(SP), AX", x64faNblk)
	w("\tMOVQ\tAX, DX")
	w("\tIMULQ\tR8, DX")
	w("\tADDQ\tDX, SI")
	w("\tMOVQ\tAX, DX")
	w("\tIMULQ\tR9, DX")
	w("\tADDQ\tDX, DI")
	w("\tTESTQ\tR10, R10")
	w("\tJZ\tfanomaskadv")
	w("\tLEAQ\t(R10)(AX*2), R10")
	w("fanomaskadv:")
	w("\tSUBQ\tAX, R11")
	w("\tJNZ\tfablk")
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
