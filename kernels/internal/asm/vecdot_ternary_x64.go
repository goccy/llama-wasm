package asm

import (
	"fmt"
	"strings"
)

// AVX2 bodies of the ternary / binary / nvfp4 dots (see
// vecdot_ternary_a64.go for the formats). The quants decode to signed
// bytes in Y2 and the activations are signed by them (VPSIGNB) so |q| is
// the u8 operand of VPMADDUBSW; every magnitude here is 0, 1 or 2 (12 for
// nvfp4), so the pair sums cannot saturate.

// x64Ternary constant blob: 0: 32 x 3; 32: 32 x 86; 64: 32 x 171; 96: 32 x
// 1; 128: kmask 1,2,..,128 x4; 160: the replicate index (each byte over
// four lanes, per 128-bit half); 192: the 2-bit field masks 3, 12, 48, 192
// repeating.
func x64TernaryConsts() []byte {
	c := make([]byte, 352)
	for i := 0; i < 32; i++ {
		c[i] = 3
		c[32+i] = 86
		c[64+i] = 171
		c[96+i] = 1
		c[128+i] = 1 << (i % 8)
		c[160+i] = byte(i % 16 / 4)
		c[192+i] = 3 << (2 * (i % 4))
		for f := 0; f < 4; f++ {
			if i%4 == f {
				c[224+32*f+i] = 3 // 224 + 32f: 3 on the lanes holding field f
			}
		}
	}
	return c
}

const (
	x64tnThree = 0
	x64tn86    = 32
	x64tn171   = 64
	x64tnOne   = 96
	x64tnKmask = 128
	x64tnRepl  = 160
	x64tnField = 192
	x64tnPos   = 224 // four 32-byte masks, one per field position
)

// x64SignedPairDot: Y5 = pair-dot of the signed bytes in Y2 against the
// activation bytes in Y3, as eight i32 lanes.
func x64SignedPairDot(w func(string, ...any), onesReg int) {
	w("\tVPSIGNB\tY2, Y2, Y5") // |q|
	w("\tVPSIGNB\tY2, Y3, Y4") // y signed by q
	w("\tVPMADDUBSW\tY4, Y5, Y5")
	w("\tVPMADDWD\tY%d, Y5, Y5", onesReg)
}

func x64VecDotTQ2_0Kernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	w := func(format string, args ...any) { fmt.Fprintf(&sb, format+"\n", args...) }
	cSym := pool.addBlob(x64QuantConsts())
	tn := pool.addBlob(x64TernaryConsts())
	w("// %s: tq2_0 x q8_K dot (AVX2), 2-bit planes shifted out.", sym)
	w("\tVXORPS\tY0, Y0, Y0")
	x64VecDotPrologue(w, wide, 8, tq2_0BlockBytes, q8_KBlockBytes, "tq2oob", "tq2reduce")
	w("\tVMOVDQU\t·%s+%d(SB), Y10", cSym, x64qcOnes)
	w("\tVMOVDQU\t·%s+%d(SB), Y11", tn, x64tnThree)
	w("\tVMOVDQU\t·%s+%d(SB), Y12", tn, x64tnOne)
	w("tq2blk:")
	w("\tVPXOR\tY1, Y1, Y1")
	for j := 0; j < 2; j++ {
		w("\tVMOVDQU\t%d(SI), Y8", 32*j)
		for l := 0; l < 4; l++ {
			if l == 0 {
				w("\tVPAND\tY11, Y8, Y2")
			} else {
				w("\tVPSRLW\t$%d, Y8, Y2", 2*l)
				w("\tVPAND\tY11, Y2, Y2")
			}
			w("\tVPSUBB\tY12, Y2, Y2") // field - 1
			w("\tVMOVDQU\t%d(DX), Y3", 4+128*j+32*l)
			x64SignedPairDot(w, 10)
			w("\tVPADDD\tY5, Y1, Y1")
		}
	}
	w("\tVCVTDQ2PS\tY1, Y1")
	x64F16Scalar(w, "SI", 64, 6)
	w("\tVMOVSS\t0(DX), X7")
	w("\tVMULSS\tX7, X6, X6")
	w("\tVBROADCASTSS\tX6, Y6")
	w("\tVFMADD231PS\tY1, Y6, Y0")
	w("\tADDQ\t$%d, SI", tq2_0BlockBytes)
	w("\tADDQ\t$%d, DX", q8_KBlockBytes)
	w("\tDECQ\tCX")
	w("\tJNZ\ttq2blk")
	w("tq2reduce:")
	x64Hsum8Store(w, false)
	w("\tVZEROUPPER")
	w("\tRET")
	w("tq2oob:")
	w("\tVZEROUPPER")
	w("\tJMP\tovr_oob")
	return sb.String()
}

// x64VecDotTQ1_0Kernel: the base-3 digit of a byte q is ~(cmp(q >= 86) +
// cmp(q >= 171)) as signed bytes; AVX2 has no unsigned byte compare, so
// each threshold is tested as max(q, t) == q. The bytes advance to the
// next digit as q*3 mod 256 = q + q + q.
func x64VecDotTQ1_0Kernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	w := func(format string, args ...any) { fmt.Fprintf(&sb, format+"\n", args...) }
	cSym := pool.addBlob(x64QuantConsts())
	tn := pool.addBlob(x64TernaryConsts())
	w("// %s: tq1_0 x q8_K dot (AVX2), base-3 digits by byte multiply and two threshold compares.", sym)
	w("\tVXORPS\tY0, Y0, Y0")
	x64VecDotPrologue(w, wide, 8, tq1_0BlockBytes, q8_KBlockBytes, "tq1oob", "tq1reduce")
	w("\tVMOVDQU\t·%s+%d(SB), Y10", cSym, x64qcOnes)
	w("\tVMOVDQU\t·%s+%d(SB), Y11", tn, x64tn86)
	w("\tVMOVDQU\t·%s+%d(SB), Y12", tn, x64tn171)
	w("\tVPCMPEQB\tY13, Y13, Y13") // all ones
	// digit: Y2 = ~(cmp86 + cmp171) of Y<q>, then q *= 3 (bytes)
	digit := func(q int) {
		w("\tVPMAXUB\tY11, Y%d, Y6", q)
		w("\tVPCMPEQB\tY%d, Y6, Y6", q) // q >= 86
		w("\tVPMAXUB\tY12, Y%d, Y7", q)
		w("\tVPCMPEQB\tY%d, Y7, Y7", q) // q >= 171
		w("\tVPADDB\tY7, Y6, Y2")
		w("\tVPXOR\tY13, Y2, Y2") // ~(0, -1, -2) = -1, 0, 1
		w("\tVPADDB\tY%d, Y%d, Y6", q, q)
		w("\tVPADDB\tY6, Y%d, Y%d", q, q) // q * 3
	}
	w("tq1blk:")
	w("\tVPXOR\tY1, Y1, Y1")
	w("\tVMOVDQU\t0(SI), Y8") // 32 bytes -> 160 quants
	for l := 0; l < 5; l++ {
		digit(8)
		w("\tVMOVDQU\t%d(DX), Y3", 4+32*l)
		x64SignedPairDot(w, 10)
		w("\tVPADDD\tY5, Y1, Y1")
	}
	w("\tVMOVDQU\t32(SI), X8") // 16 bytes -> 80 quants (lanes 16..31 zero)
	w("\tVPXOR\tY9, Y9, Y9")
	w("\tVINSERTI128\t$1, X9, Y8, Y8")
	for l := 0; l < 5; l++ {
		digit(8)
		w("\tVMOVDQU\t%d(DX), X3", 4+160+16*l)
		w("\tVINSERTI128\t$1, X9, Y3, Y3")
		x64SignedPairDot(w, 10)
		w("\tVPADDD\tY5, Y1, Y1")
	}
	w("\tVMOVD\t48(SI), X8") // 4 bytes qh -> 16 quants
	w("\tVINSERTI128\t$1, X9, Y8, Y8")
	for l := 0; l < 4; l++ {
		digit(8)
		w("\tVMOVD\t%d(DX), X3", 4+240+4*l)
		w("\tVINSERTI128\t$1, X9, Y3, Y3")
		x64SignedPairDot(w, 10)
		w("\tVPADDD\tY5, Y1, Y1")
	}
	w("\tVCVTDQ2PS\tY1, Y1")
	x64F16Scalar(w, "SI", 52, 6)
	w("\tVMOVSS\t0(DX), X7")
	w("\tVMULSS\tX7, X6, X6")
	w("\tVBROADCASTSS\tX6, Y6")
	w("\tVFMADD231PS\tY1, Y6, Y0")
	w("\tADDQ\t$%d, SI", tq1_0BlockBytes)
	w("\tADDQ\t$%d, DX", q8_KBlockBytes)
	w("\tDECQ\tCX")
	w("\tJNZ\ttq1blk")
	w("tq1reduce:")
	x64Hsum8Store(w, false)
	w("\tVZEROUPPER")
	w("\tRET")
	w("tq1oob:")
	w("\tVZEROUPPER")
	w("\tJMP\tovr_oob")
	return sb.String()
}

// x64VecDotQ1_0Kernel: q1_0 x q8_0. The 32 sign bits of an activation
// block spread over 32 lanes (VPSHUFB byte spread, kmask test) become
// -1 where set / +1 where clear (the negated sign), so the block's f32 sum
// is subtracted with its d1 * d0 weight.
func x64VecDotQ1_0Kernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	w := func(format string, args ...any) { fmt.Fprintf(&sb, format+"\n", args...) }
	cSym := pool.addBlob(x64QuantConsts())
	tn := pool.addBlob(x64TernaryConsts())
	w("// %s: q1_0 x q8_0 dot (AVX2), sign bits to +-1 bytes, one pair dot per activation block.", sym)
	w("\tVXORPS\tY0, Y0, Y0")
	x64VecDotPrologue(w, wide, 7, q1_0BlockBytes, 4*q8_0BlockBytes, "q1oob", "q1reduce")
	w("\tVMOVDQU\t·%s+%d(SB), Y10", cSym, x64qcOnes)
	w("\tVMOVDQU\t·%s+%d(SB), Y11", cSym, x64qcSpread)
	w("\tVMOVDQU\t·%s+%d(SB), Y12", tn, x64tnKmask)
	w("\tVMOVDQU\t·%s+%d(SB), Y13", tn, x64tnOne)
	w("q1blk:")
	x64F16Scalar(w, "SI", 0, 9) // d0
	for k := 0; k < 4; k++ {
		w("\tVMOVD\t%d(SI), X2", 2+4*k)
		w("\tVPBROADCASTD\tX2, Y2")
		w("\tVPSHUFB\tY11, Y2, Y2") // [b0 x8 | b1 x8 | b2 x8 | b3 x8]
		w("\tVPAND\tY12, Y2, Y2")
		w("\tVPCMPEQB\tY12, Y2, Y2") // 0xff where set
		w("\tVPOR\tY13, Y2, Y2")     // -1 where set, +1 where clear
		w("\tVMOVDQU\t%d(DX), Y3", 34*k+2)
		x64SignedPairDot(w, 10)
		w("\tVCVTDQ2PS\tY5, Y5")
		x64F16Scalar(w, "DX", 34*k, 6) // d1
		w("\tVMULSS\tX9, X6, X6")
		w("\tVBROADCASTSS\tX6, Y6")
		w("\tVFNMADD231PS\tY5, Y6, Y0") // acc -= d0*d1 * (-sum)
	}
	w("\tADDQ\t$%d, SI", q1_0BlockBytes)
	w("\tADDQ\t$%d, DX", 4*q8_0BlockBytes)
	w("\tDECQ\tCX")
	w("\tJNZ\tq1blk")
	w("q1reduce:")
	x64Hsum8Store(w, false)
	w("\tVZEROUPPER")
	w("\tRET")
	w("q1oob:")
	w("\tVZEROUPPER")
	w("\tJMP\tovr_oob")
	return sb.String()
}

// x64VecDotQ2_0Kernel: q2_0 x q8_0. Each byte of an activation block is
// replicated over four lanes (VPSHUFB per half), then shifted right by 0,
// 2, 4 and 6 (16-bit shifts are exact here because both bytes of a word
// hold the same byte and the result is masked to 2 bits), each shift kept
// only on the lanes of its field position, or'ed together and offset by -1.
func x64VecDotQ2_0Kernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	w := func(format string, args ...any) { fmt.Fprintf(&sb, format+"\n", args...) }
	cSym := pool.addBlob(x64QuantConsts())
	tn := pool.addBlob(x64TernaryConsts())
	w("// %s: q2_0 x q8_0 dot (AVX2), bytes replicated over their four fields, shifted, masked and normalised.", sym)
	w("\tVXORPS\tY0, Y0, Y0")
	x64VecDotPrologue(w, wide, 6, q2_0BlockBytes, 2*q8_0BlockBytes, "q2oob", "q2reduce")
	w("\tVMOVDQU\t·%s+%d(SB), Y10", cSym, x64qcOnes)
	w("\tVMOVDQU\t·%s+%d(SB), Y11", tn, x64tnRepl)
	w("\tVMOVDQU\t·%s+%d(SB), Y13", tn, x64tnOne)
	w("q2blk:")
	x64F16Scalar(w, "SI", 0, 9) // d0
	for k := 0; k < 2; k++ {
		w("\tVMOVD\t%d(SI), X2", 2+8*k)
		w("\tVMOVD\t%d(SI), X8", 2+8*k+4)
		w("\tVINSERTI128\t$1, X8, Y2, Y2")
		w("\tVPSHUFB\tY11, Y2, Y2")                    // [bytes 0..3 each x4 | bytes 4..7 each x4]
		w("\tVPAND\t·%s+%d(SB), Y2, Y8", tn, x64tnPos) // field 0 lanes
		for f := 1; f < 4; f++ {
			w("\tVPSRLW\t$%d, Y2, Y6", 2*f)
			w("\tVPAND\t·%s+%d(SB), Y6, Y6", tn, x64tnPos+32*f)
			w("\tVPOR\tY6, Y8, Y8")
		}
		w("\tVPSUBB\tY13, Y8, Y2") // field - 1
		w("\tVMOVDQU\t%d(DX), Y3", 34*k+2)
		x64SignedPairDot(w, 10)
		w("\tVCVTDQ2PS\tY5, Y5")
		x64F16Scalar(w, "DX", 34*k, 6) // d1
		w("\tVMULSS\tX9, X6, X6")
		w("\tVBROADCASTSS\tX6, Y6")
		w("\tVFMADD231PS\tY5, Y6, Y0")
	}
	w("\tADDQ\t$%d, SI", q2_0BlockBytes)
	w("\tADDQ\t$%d, DX", 2*q8_0BlockBytes)
	w("\tDECQ\tCX")
	w("\tJNZ\tq2blk")
	w("q2reduce:")
	x64Hsum8Store(w, false)
	w("\tVZEROUPPER")
	w("\tRET")
	w("q2oob:")
	w("\tVZEROUPPER")
	w("\tJMP\tovr_oob")
	return sb.String()
}

// x64VecDotNVFP4Kernel: nvfp4 x q8_0. Each 16-quant sub-block's nibbles go
// through the kvalues table in a 128-bit register (the upper half of the
// 256-bit operands stays zero so the wide pair dot and FMA stay valid);
// its UE4M3 scale comes from the f32 table.
func x64VecDotNVFP4Kernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	w := func(format string, args ...any) { fmt.Fprintf(&sb, format+"\n", args...) }
	cSym := pool.addBlob(x64QuantConsts())
	nv := pool.addBlob(nvfp4Consts())
	w("// %s: nvfp4 x q8_0 dot (AVX2), fp4 nibbles through VPSHUFB, UE4M3 sub-block scales through a table.", sym)
	w("\tVXORPS\tY0, Y0, Y0")
	x64VecDotPrologue(w, wide, 6, nvfp4BlockBytes, 2*q8_0BlockBytes, "nvoob", "nvreduce")
	w("\tMOVQ\t$·%s(SB), R12", nv)
	w("\tVMOVDQU\t·%s+%d(SB), Y10", cSym, x64qcOnes)
	w("\tVMOVDQU\t·%s+%d(SB), X11", cSym, x64qcFP4)
	w("\tVMOVDQU\t·%s+%d(SB), X8", cSym, x64qcLow)
	w("\tVPXOR\tY9, Y9, Y9")
	w("nvblk:")
	for sIdx := 0; sIdx < 4; sIdx++ {
		q8 := sIdx / 2
		off := (sIdx % 2) * 16
		w("\tVMOVQ\t%d(SI), X2", 4+8*sIdx) // 8 nibble bytes
		w("\tVPSRLW\t$4, X2, X3")
		w("\tVPUNPCKLQDQ\tX3, X2, X2") // [low nibbles | high nibbles]
		w("\tVPAND\tX8, X2, X2")
		w("\tVPSHUFB\tX2, X11, X2")
		w("\tVINSERTI128\t$1, X9, Y2, Y2")
		w("\tVMOVDQU\t%d(DX), X3", 34*q8+2+off)
		w("\tVINSERTI128\t$1, X9, Y3, Y3")
		x64SignedPairDot(w, 10)
		w("\tVCVTDQ2PS\tY5, Y5")
		w("\tMOVBLZX\t%d(SI), R8", sIdx)
		w("\tVMOVSS\t(R12)(R8*4), X6")  // ue4m3(d[s])
		x64F16Scalar(w, "DX", 34*q8, 7) // dy
		w("\tVMULSS\tX7, X6, X6")
		w("\tVBROADCASTSS\tX6, Y6")
		w("\tVFMADD231PS\tY5, Y6, Y0")
	}
	w("\tADDQ\t$%d, SI", nvfp4BlockBytes)
	w("\tADDQ\t$%d, DX", 2*q8_0BlockBytes)
	w("\tDECQ\tCX")
	w("\tJNZ\tnvblk")
	w("nvreduce:")
	x64Hsum8Store(w, false)
	w("\tVZEROUPPER")
	w("\tRET")
	w("nvoob:")
	w("\tVZEROUPPER")
	w("\tJMP\tovr_oob")
	return sb.String()
}
