package asm

import (
	"fmt"
	"strings"
)

// x64VecDotIQ1SKernel / x64VecDotIQ1MKernel: the iq1 dots on AVX2 (see
// vecdot_iq1_a64.go). Four u64 grid gathers per sub-block through VPINSRQ
// give 32 signed ternary bytes; the sign trick (|g| as the u8 operand, the
// activations signed by g) feeds VPMADDUBSW/VPMADDWD into eight i32 lanes
// weighted by the sub-block (iq1_s) or per-16-quant (iq1_m) scale. The
// delta term is the activation sums times +-1 times the scale: iq1_s takes
// the block's bsums through general registers, iq1_m the SDOT-equivalent
// of the activations against +-1 bytes. Both totals combine as sumi + 0.125
// * sumi_delta before the block scale.
func x64VecDotIQ1SKernel(sym string, pool *ConstPool, wide bool) string {
	return x64VecDotIQ1(sym, pool, wide, false)
}

func x64VecDotIQ1MKernel(sym string, pool *ConstPool, wide bool) string {
	return x64VecDotIQ1(sym, pool, wide, true)
}

func x64VecDotIQ1(sym string, pool *ConstPool, wide bool, iq1m bool) string {
	var sb strings.Builder
	w := func(format string, args ...any) { fmt.Fprintf(&sb, format+"\n", args...) }
	cSym := pool.addBlob(x64QuantConsts())
	grid := pool.addBlob(iq1Consts())
	name, lbl, blockBytes := "iq1_s", "i1s", iq1_sBlockBytes
	if iq1m {
		name, lbl, blockBytes = "iq1_m", "i1m", iq1_mBlockBytes
	}
	w("// %s: %s x q8_K dot (AVX2), u64 grid gathers through VPINSRQ, sign-trick pair dot, delta term.", sym, name)
	w("\tVXORPS\tY0, Y0, Y0")
	x64VecDotPrologue(w, wide, 8, blockBytes, q8_KBlockBytes, lbl+"oob", lbl+"reduce")
	w("\tMOVQ\t$·%s(SB), R12", grid)
	w("\tVMOVDQU\t·%s+%d(SB), Y10", cSym, x64qcOnes)
	if iq1m {
		w("\tVMOVDQU\t16384(R12), X11") // [0x08 x8 | 0x80 x8]
		w("\tVINSERTI128\t$1, X11, Y11, Y11")
		w("\tVMOVDQU\t·%s+%d(SB), Y13", cSym, x64qcB1)
	}
	w("%sblk:", lbl)
	w("\tVPXOR\tY1, Y1, Y1") // sumi
	w("\tVPXOR\tY9, Y9, Y9") // sumi_delta (iq1_m) as i32 lanes
	w("\tXORL\tR11, R11")    // sumi_delta (iq1_s) scalar
	for ib := 0; ib < 8; ib++ {
		if iq1m {
			w("\tMOVWLZX\t%d(SI), R9", 32+2*ib)      // two qh bytes
			w("\tMOVWLZX\t%d(SI), R10", 48+2*(ib/2)) // scale word
		} else {
			w("\tMOVWLZX\t%d(SI), R9", 34+2*ib) // qh: index bits | scale | delta sign
		}
		for l := 0; l < 4; l++ {
			if iq1m {
				w("\tMOVBLZX\t%d(SI), R14", 4*ib+l)
				w("\tMOVL\tR9, R8")
				w("\tSHRL\t$%d, R8", 4*l)
				w("\tANDL\t$7, R8")
			} else {
				w("\tMOVBLZX\t%d(SI), R14", 2+4*ib+l)
				w("\tMOVL\tR9, R8")
				w("\tSHRL\t$%d, R8", 3*l)
				w("\tANDL\t$7, R8")
			}
			w("\tSHLL\t$8, R8")
			w("\tORL\tR8, R14")
			w("\tMOVQ\t(R12)(R14*8), R15")
			if l < 2 {
				w("\tVPINSRQ\t$%d, R15, X2, X2", l)
			} else {
				w("\tVPINSRQ\t$%d, R15, X5, X5", l-2)
			}
		}
		w("\tVINSERTI128\t$1, X5, Y2, Y2") // 32 ternary bytes
		w("\tVMOVDQU\t%d(DX), Y3", 4+32*ib)
		w("\tVPSIGNB\tY2, Y2, Y5") // |g|
		w("\tVPSIGNB\tY2, Y3, Y4") // y signed by g (0 where g == 0)
		w("\tVPMADDUBSW\tY4, Y5, Y5")
		w("\tVPMADDWD\tY10, Y5, Y5")
		if iq1m {
			// delta signs: byte qh[0] flags groups 0/1, qh[1] groups 2/3
			w("\tVMOVD\tR9, X6")
			w("\tVPBROADCASTW\tX6, Y6")
			w("\tVPSHUFB\t·%s+%d(SB), Y6, Y6", cSym, x64qcSpread2)
			w("\tVPAND\tY11, Y6, Y6")
			w("\tVPCMPEQB\tY11, Y6, Y6")
			w("\tVPOR\tY13, Y6, Y6") // -1 / +1 per group
			// activation sums per group with the group's sign: VPMADDUBSW(y signed, ones)
			w("\tVPSIGNB\tY6, Y3, Y7")
			w("\tVPMADDUBSW\tY7, Y13, Y7")
			w("\tVPMADDWD\tY10, Y7, Y7")
			// scales: ls1 for lanes 0..3 (groups 0/1), ls2 for lanes 4..7
			w("\tMOVL\tR10, R8")
			w("\tSHRL\t$%d, R8", 6*(ib%2))
			w("\tANDL\t$7, R8")
			w("\tLEAL\t1(R8)(R8*1), R8")
			w("\tMOVL\tR10, R9")
			w("\tSHRL\t$%d, R9", 6*(ib%2)+3)
			w("\tANDL\t$7, R9")
			w("\tLEAL\t1(R9)(R9*1), R9")
			w("\tVMOVD\tR8, X6")
			w("\tVMOVD\tR9, X8")
			w("\tVPBROADCASTD\tX6, X6")
			w("\tVPBROADCASTD\tX8, X8")
			w("\tVINSERTI128\t$1, X8, Y6, Y6")
			w("\tVPMULLD\tY6, Y5, Y5")
			w("\tVPADDD\tY5, Y1, Y1")
			w("\tVPMULLD\tY6, Y7, Y7")
			w("\tVPADDD\tY7, Y9, Y9")
		} else {
			w("\tMOVL\tR9, R8")
			w("\tSHRL\t$12, R8")
			w("\tANDL\t$7, R8")
			w("\tLEAL\t1(R8)(R8*1), R8") // ls
			w("\tVMOVD\tR8, X6")
			w("\tVPBROADCASTD\tX6, Y6")
			w("\tVPMULLD\tY6, Y5, Y5")
			w("\tVPADDD\tY5, Y1, Y1")
			// delta: ls * (+-1) * (bsums[2ib] + bsums[2ib+1])
			w("\tMOVWLSX\t%d(DX), R14", 260+4*ib)
			w("\tMOVWLSX\t%d(DX), R15", 262+4*ib)
			w("\tADDL\tR15, R14")
			w("\tIMULL\tR8, R14")
			w("\tTESTL\t$0x8000, R9")
			w("\tJZ\t%spos%d", lbl, ib)
			w("\tNEGL\tR14")
			w("%spos%d:", lbl, ib)
			w("\tADDL\tR14, R11")
		}
	}
	// block total = sumi + 0.125 * sumi_delta, scaled by d * y.d
	if iq1m {
		w("\tVCVTDQ2PS\tY9, Y9")
		w("\tMOVL\t$0x3E000000, R8")
		w("\tVMOVD\tR8, X8")
		w("\tVBROADCASTSS\tX8, Y8")
		w("\tVCVTDQ2PS\tY1, Y1")
		w("\tVFMADD231PS\tY9, Y8, Y1")
		// the block scale from the four scale words' top nibbles
		w("\tMOVWLZX\t48(SI), R8")
		w("\tSHRL\t$12, R8")
		w("\tMOVWLZX\t50(SI), R9")
		w("\tSHRL\t$8, R9")
		w("\tANDL\t$0xf0, R9")
		w("\tORL\tR9, R8")
		w("\tMOVWLZX\t52(SI), R9")
		w("\tSHRL\t$4, R9")
		w("\tANDL\t$0xf00, R9")
		w("\tORL\tR9, R8")
		w("\tMOVWLZX\t54(SI), R9")
		w("\tANDL\t$0xf000, R9")
		w("\tORL\tR9, R8")
		w("\tVMOVD\tR8, X6")
		w("\tVCVTPH2PS\tX6, X6")
	} else {
		w("\tVCVTDQ2PS\tY1, Y1")
		w("\tVCVTSI2SSL\tR11, X8, X8")
		w("\tMOVL\t$0x3E000000, R9")
		w("\tVMOVD\tR9, X9")
		w("\tVMULSS\tX9, X8, X8") // 0.125 * sumi_delta, added to lane 0 below through X1's upper-lane-preserving path
		w("\tVEXTRACTF128\t$1, Y1, X9")
		w("\tVADDPS\tX9, X1, X1")
		w("\tVADDSS\tX8, X1, X1") // Y1 now carries the total in its low half (upper half consumed)
		w("\tVPXOR\tX9, X9, X9")
		w("\tVINSERTI128\t$1, X9, Y1, Y1")
		x64F16Scalar(w, "SI", 0, 6)
	}
	w("\tVMOVSS\t0(DX), X7")
	w("\tVMULSS\tX7, X6, X6")
	w("\tVBROADCASTSS\tX6, Y6")
	w("\tVFMADD231PS\tY1, Y6, Y0")
	w("\tADDQ\t$%d, SI", blockBytes)
	w("\tADDQ\t$%d, DX", q8_KBlockBytes)
	w("\tDECQ\tCX")
	w("\tJNZ\t%sblk", lbl)
	w("%sreduce:", lbl)
	x64Hsum8Store(w, false)
	w("\tVZEROUPPER")
	w("\tRET")
	w("%soob:", lbl)
	w("\tVZEROUPPER")
	w("\tJMP\tovr_oob")
	return sb.String()
}
