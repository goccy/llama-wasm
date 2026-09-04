package asm

import (
	"fmt"
	"strings"
)

// amd64 (AVX2) bodies of the quantized dots, after llama.cpp's own
// AVX2 paths: a 32-quant block lives in one ymm, the u8 x s8 products
// go through VPMADDUBSW (pairs to i16) and VPMADDWD against the
// per-group scales (to i32), and every super-block converts once into
// an f32 fused accumulate. FastMath only.
//
// Register contract (docs/asm-overrides.md): R14 memory base, R15
// memory size, AX clobberable. CX = nb, DI = s, SI = x, DX = y.

// x64QuantConsts is the shared constant blob:
//
//	  0: 32 x 0x0f
//	 32: 32 x 0xf0
//	 64: 16 x i16 1
//	 96: bytes_from_bits_32 shuffle (byte i/8 of the u32, per lane)
//	128: bytes_from_bits_32 bit mask 0x7fbfdfeff7fbfdfe x4
//	160: 32 x 0x03  192: 32 x 0x0c  224: 32 x 0x30  256: 32 x 0xc0
//	288: get_scale_shuffle_k4 (8 rows x 32 bytes: word i of row r is 2r,2r+1)
//	544: get_scale_shuffle    (8 rows x 16 bytes: row r is 2r x8, 2r+1 x8)
//	672: end
func x64QuantConsts() []byte {
	c := make([]byte, 672)
	fill := func(off int, b byte) {
		for i := 0; i < 32; i++ {
			c[off+i] = b
		}
	}
	fill(0, 0x0f)
	fill(32, 0xf0)
	for i := 0; i < 16; i++ {
		c[64+2*i] = 1
	}
	for i := 0; i < 32; i++ {
		c[96+i] = byte(i / 8)
	}
	mask := uint64(0x7fbfdfeff7fbfdfe)
	for r := 0; r < 4; r++ {
		for i := 0; i < 8; i++ {
			c[128+8*r+i] = byte(mask >> (8 * i))
		}
	}
	fill(160, 0x03)
	fill(192, 0x0c)
	fill(224, 0x30)
	fill(256, 0xc0)
	for r := 0; r < 8; r++ {
		for i := 0; i < 16; i++ {
			c[288+32*r+2*i] = byte(2 * r)
			c[288+32*r+2*i+1] = byte(2*r + 1)
		}
		for i := 0; i < 8; i++ {
			c[544+16*r+i] = byte(2 * r)
			c[544+16*r+8+i] = byte(2*r + 1)
		}
	}
	return c
}

const (
	x64qcLow   = 0
	x64qcHigh  = 32
	x64qcOnes  = 64
	x64qcBits  = 96
	x64qcBitM  = 128
	x64qcM3    = 160
	x64qcM12   = 192
	x64qcM48   = 224
	x64qcM192  = 256
	x64qcK4    = 288
	x64qcScale = 544
)

// x64VecDotPrologue: CX = n >> shift, DI = s (host), SI = x (host), DX
// = y (host), with the three ranges checked; a zero block count jumps
// to zeroLabel with nothing loaded but s.
func x64VecDotPrologue(w func(string, ...any), wide bool, shift, xBlock, yBlock int, oob, zeroLabel string) {
	args, _ := vecDotArgs(wide)
	movPtr := "MOVL"
	if wide {
		movPtr = "MOVQ"
	}
	w("\tMOVLQSX\tl0+%d(FP), CX", args["l0"])
	w("\tSHRQ\t$%d, CX", shift)
	w("\t%s\tl1+%d(FP), DI", movPtr, args["l1"])
	w("\tLEAQ\t4(DI), R8")
	w("\tCMPQ\tR15, R8")
	w("\tJCS\t%s", oob)
	w("\tADDQ\tR14, DI")
	w("\tTESTQ\tCX, CX")
	w("\tJZ\t%s", zeroLabel)
	w("\t%s\tl3+%d(FP), SI", movPtr, args["l3"])
	w("\t%s\tl5+%d(FP), DX", movPtr, args["l5"])
	w("\tIMUL3Q\t$%d, CX, R8", xBlock)
	w("\tADDQ\tSI, R8")
	w("\tCMPQ\tR15, R8")
	w("\tJCS\t%s", oob)
	w("\tIMUL3Q\t$%d, CX, R8", yBlock)
	w("\tADDQ\tDX, R8")
	w("\tCMPQ\tR15, R8")
	w("\tJCS\t%s", oob)
	w("\tADDQ\tR14, SI")
	w("\tADDQ\tR14, DX")
}

// x64Hsum8Store: *(DI) = horizontal sum of the eight f32 lanes of Y0
// (+ the four of X1 when withX1).
func x64Hsum8Store(w func(string, ...any), withX1 bool) {
	w("\tVEXTRACTF128\t$1, Y0, X2")
	w("\tVADDPS\tX2, X0, X0")
	if withX1 {
		w("\tVADDPS\tX1, X0, X0")
	}
	w("\tVHADDPS\tX0, X0, X0")
	w("\tVHADDPS\tX0, X0, X0")
	w("\tVMOVSS\tX0, (DI)")
}

// x64TilePrologue checks the nrc == 2 ranges (s + 8, s + 4*bs + 8,
// x + bx + nb*xBlock, y + by + nb*yBlock) without loading pointers;
// x64ComboPointers then sets CX/SI/DX/DI for one of the four
// (row, column) dots from the frame. The amd64 bodies run the tile as
// four single dots: llama.cpp's own x86 path has no nrc == 2 either.
func x64TilePrologue(w func(string, ...any), wide bool, shift, xBlock, yBlock int, oob string) {
	args, _ := vecDotArgs(wide)
	movPtr := "MOVL"
	if wide {
		movPtr = "MOVQ"
	}
	w("\tMOVLQSX\tl0+%d(FP), CX", args["l0"])
	w("\tSHRQ\t$%d, CX", shift)
	w("\t%s\tl1+%d(FP), DI", movPtr, args["l1"])
	w("\tLEAQ\t8(DI), R8")
	w("\tCMPQ\tR15, R8")
	w("\tJCS\t%s", oob)
	w("\t%s\tl2+%d(FP), R8", movPtr, args["l2"])
	w("\tLEAQ\t8(DI)(R8*4), R8")
	w("\tCMPQ\tR15, R8")
	w("\tJCS\t%s", oob)
	w("\t%s\tl3+%d(FP), SI", movPtr, args["l3"])
	w("\tADDQ\tl4+%d(FP), SI", args["l4"])
	w("\tIMUL3Q\t$%d, CX, R8", xBlock)
	w("\tADDQ\tSI, R8")
	w("\tCMPQ\tR15, R8")
	w("\tJCS\t%s", oob)
	w("\t%s\tl5+%d(FP), DX", movPtr, args["l5"])
	w("\tADDQ\tl6+%d(FP), DX", args["l6"])
	w("\tIMUL3Q\t$%d, CX, R8", yBlock)
	w("\tADDQ\tDX, R8")
	w("\tCMPQ\tR15, R8")
	w("\tJCS\t%s", oob)
}

func x64ComboPointers(w func(string, ...any), wide bool, shift, r, c int) {
	args, _ := vecDotArgs(wide)
	movPtr := "MOVL"
	if wide {
		movPtr = "MOVQ"
	}
	w("\tMOVLQSX\tl0+%d(FP), CX", args["l0"])
	w("\tSHRQ\t$%d, CX", shift)
	w("\t%s\tl3+%d(FP), SI", movPtr, args["l3"])
	if r == 1 {
		w("\tADDQ\tl4+%d(FP), SI", args["l4"])
	}
	w("\tADDQ\tR14, SI")
	w("\t%s\tl5+%d(FP), DX", movPtr, args["l5"])
	if c == 1 {
		w("\tADDQ\tl6+%d(FP), DX", args["l6"])
	}
	w("\tADDQ\tR14, DX")
	w("\t%s\tl1+%d(FP), DI", movPtr, args["l1"])
	if r == 1 {
		w("\tADDQ\t$4, DI")
	}
	if c == 1 {
		w("\t%s\tl2+%d(FP), R8", movPtr, args["l2"])
		w("\tLEAQ\t(DI)(R8*4), DI")
	}
	w("\tADDQ\tR14, DI")
}

// x64NrcDispatch emits the nrc == 1 / nrc == 2 split around body: body
// writes one dot for the pointers in CX/SI/DX/DI (nb may be zero) and
// takes a label suffix. prologueOnce loads whatever the bodies share.
func x64NrcDispatch(w func(string, ...any), wide bool, shift, xBlock, yBlock int, lbl string, prologueOnce func(), body func(suffix string)) {
	args, _ := vecDotArgs(wide)
	w("\tMOVL\tl7+%d(FP), AX", args["l7"])
	w("\tCMPL\tAX, $2")
	w("\tJEQ\t%stile", lbl)
	x64VecDotPrologue(w, wide, shift, xBlock, yBlock, lbl+"oob", lbl+"one")
	w("%sone:", lbl)
	prologueOnce()
	body("")
	w("\tVZEROUPPER")
	w("\tRET")
	w("%stile:", lbl)
	x64TilePrologue(w, wide, shift, xBlock, yBlock, lbl+"oob")
	prologueOnce()
	for i, rc := range [][2]int{{0, 0}, {1, 0}, {0, 1}, {1, 1}} {
		x64ComboPointers(w, wide, shift, rc[0], rc[1])
		body(string(rune('a' + i)))
	}
	w("\tVZEROUPPER")
	w("\tRET")
	w("%soob:", lbl)
	w("\tVZEROUPPER")
	w("\tJMP\tovr_oob")
}

// x64F16Scalar loads the f16 at off(reg) widened into X<dst> (scalar).
func x64F16Scalar(w func(string, ...any), reg string, off, dst int) {
	w("\tMOVWLZX\t%d(%s), R8", off, reg)
	w("\tVMOVD\tR8, X%d", dst)
	w("\tVCVTPH2PS\tX%d, X%d", dst, dst)
}

// x64VecDotQ5_0Kernel: q5_0 x q8_0 on AVX2 (see a64VecDotQ5_0Kernel).
// Per block: nibbles to bytes, the fifth bits through the broadcast/
// shuffle/compare idiom folded in as 0xf0 where clear (so the byte
// reads as nibble-16 signed), then the sign-trick u8 x s8 pair dot.
func x64VecDotQ5_0Kernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	w := func(format string, args ...any) { fmt.Fprintf(&sb, format+"\n", args...) }
	cSym := pool.addBlob(x64QuantConsts())
	w("// %s: q5_0 x q8_0 dot (AVX2).", sym)
	w("\tVXORPS\tY0, Y0, Y0")
	x64VecDotPrologue(w, wide, 5, q5_0BlockBytes, q8_0BlockBytes, "q5oob", "q5reduce")
	w("\tVMOVDQU\t·%s+%d(SB), Y8", cSym, x64qcLow)
	w("\tVMOVDQU\t·%s+%d(SB), Y9", cSym, x64qcHigh)
	w("\tVMOVDQU\t·%s+%d(SB), Y10", cSym, x64qcOnes)
	w("\tVMOVDQU\t·%s+%d(SB), Y11", cSym, x64qcBits)
	w("\tVMOVDQU\t·%s+%d(SB), Y12", cSym, x64qcBitM)
	w("\tVPCMPEQB\tY13, Y13, Y13") // all ones
	w("q5blk:")
	// qx = bytes_from_nibbles_32(qs)
	w("\tVMOVDQU\t6(SI), X2")
	w("\tVPSRLW\t$4, X2, X3")
	w("\tVINSERTI128\t$1, X3, Y2, Y2")
	w("\tVPAND\tY8, Y2, Y2")
	// bxhi = bytes_from_bits_32(qh); qx |= ~bxhi & 0xf0
	w("\tVPBROADCASTD\t2(SI), Y3")
	w("\tVPSHUFB\tY11, Y3, Y3")
	w("\tVPOR\tY12, Y3, Y3")
	w("\tVPCMPEQB\tY13, Y3, Y3")
	w("\tVPANDN\tY9, Y3, Y3")
	w("\tVPOR\tY3, Y2, Y2")
	// mul_sum_i8_pairs: ax = |qx|, sy = sign(qy, qx)
	w("\tVMOVDQU\t2(DX), Y4")
	w("\tVPSIGNB\tY2, Y2, Y5")
	w("\tVPSIGNB\tY2, Y4, Y4")
	w("\tVPMADDUBSW\tY4, Y5, Y5")
	w("\tVPMADDWD\tY10, Y5, Y5")
	w("\tVCVTDQ2PS\tY5, Y5")
	// d = f16(x.d) * f16(y.d)
	x64F16Scalar(w, "SI", 0, 6)
	x64F16Scalar(w, "DX", 0, 7)
	w("\tVMULSS\tX7, X6, X6")
	w("\tVBROADCASTSS\tX6, Y6")
	w("\tVFMADD231PS\tY5, Y6, Y0")
	w("\tADDQ\t$%d, SI", q5_0BlockBytes)
	w("\tADDQ\t$%d, DX", q8_0BlockBytes)
	w("\tDECQ\tCX")
	w("\tJNZ\tq5blk")
	w("q5reduce:")
	x64Hsum8Store(w, false)
	w("\tVZEROUPPER")
	w("\tRET")
	w("q5oob:")
	w("\tVZEROUPPER")
	w("\tJMP\tovr_oob")
	return sb.String()
}

// x64VecDotQ4_KKernel: q4_K x q8_K on AVX2 (see a64VecDotQ4_KKernel).
// Y0 accumulates d * sumi over blocks, X1 the mins term (-dmin * prod).
func x64VecDotQ4_KKernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	w := func(format string, args ...any) { fmt.Fprintf(&sb, format+"\n", args...) }
	cSym := pool.addBlob(x64QuantConsts())
	w("// %s: q4_K x q8_K dot (AVX2); nrc == 2 runs the four dots of the tile.", sym)
	once := func() {
		w("\tVMOVDQU\t·%s+%d(SB), Y8", cSym, x64qcLow)
		w("\tLEAQ\t·%s+%d(SB), R11", cSym, x64qcK4)
	}
	body := func(sfx string) {
		w("\tVXORPS\tY0, Y0, Y0")
		w("\tVXORPS\tX1, X1, X1")
		w("\tTESTQ\tCX, CX")
		w("\tJZ\tq4kred%s", sfx)
		w("q4kblk%s:", sfx)
		// utmp[0..2] -> R9, R10, R12 (R8 is the f16 scratch).
		w("\tMOVL\t4(SI), R9")
		w("\tMOVL\t8(SI), R10")
		w("\tMOVL\t12(SI), R12")
		// utmp[3] = ((utmp2 >> 4) & kmask2) | (((utmp1 >> 6) & kmask3) << 4)
		w("\tMOVL\tR12, R13")
		w("\tSHRL\t$4, R13")
		w("\tANDL\t$0x0f0f0f0f, R13")
		w("\tMOVL\tR10, BX")
		w("\tSHRL\t$6, BX")
		w("\tANDL\t$0x03030303, BX")
		w("\tSHLL\t$4, BX")
		w("\tORL\tBX, R13") // utmp3 (mins 4..7)
		// uaux = utmp1 & kmask1 (mins 0..3)
		w("\tMOVL\tR10, BX")
		w("\tANDL\t$0x3f3f3f3f, BX")
		// utmp[1] = (utmp2 & kmask2) | (((utmp0 >> 6) & kmask3) << 4) (scales 4..7)
		w("\tANDL\t$0x0f0f0f0f, R12")
		w("\tMOVL\tR9, R10")
		w("\tSHRL\t$6, R10")
		w("\tANDL\t$0x03030303, R10")
		w("\tSHLL\t$4, R10")
		w("\tORL\tR12, R10")
		// utmp[0] &= kmask1 (scales 0..3)
		w("\tANDL\t$0x3f3f3f3f, R9")
		// X2 = [utmp0, utmp1, uaux, utmp3] as 16 bytes: sc0..7, m0..7
		w("\tVMOVD\tR9, X2")
		w("\tVPINSRD\t$1, R10, X2, X2")
		w("\tVPINSRD\t$2, BX, X2, X2")
		w("\tVPINSRD\t$3, R13, X2, X2")
		w("\tVPMOVZXBW\tX2, Y2") // 16 words: scales (low 128), mins (high 128)
		w("\tVEXTRACTI128\t$1, Y2, X3")
		// q8s = hadd(bsums lo, bsums hi); prod = madd(mins, q8s)
		w("\tVMOVDQU\t260(DX), X4")
		w("\tVMOVDQU\t276(DX), X5")
		w("\tVPHADDW\tX5, X4, X4")
		w("\tVPMADDWD\tX4, X3, X3")
		w("\tVCVTDQ2PS\tX3, X3")
		// dmin = -y.d * f16(x.dmin); d = y.d * f16(x.d)
		w("\tVMOVSS\t(DX), X7")
		x64F16Scalar(w, "SI", 2, 6)
		w("\tVMULSS\tX7, X6, X6")
		w("\tVBROADCASTSS\tX6, X6")
		w("\tVFNMADD231PS\tX3, X6, X1") // acc_m -= dmin * prod
		x64F16Scalar(w, "SI", 0, 6)
		w("\tVMULSS\tX7, X6, X6")
		w("\tVBROADCASTSS\tX6, Y6")
		// scales broadcast to both lanes: Y2 = [sc128, sc128]
		w("\tVINSERTI128\t$1, X2, Y2, Y2")
		w("\tVPXOR\tY7, Y7, Y7") // sumi
		for j := 0; j < 4; j++ {
			w("\tVMOVDQU\t%d(SI), Y3", 16+32*j)
			w("\tVPSRLW\t$4, Y3, Y4")
			w("\tVPAND\tY8, Y3, Y3")
			w("\tVPAND\tY8, Y4, Y4")
			w("\tVPMADDUBSW\t%d(DX), Y3, Y3", 4+64*j)
			w("\tVPMADDUBSW\t%d(DX), Y4, Y4", 4+64*j+32)
			w("\tVPSHUFB\t%d(R11), Y2, Y5", 32*(2*j))
			w("\tVPMADDWD\tY3, Y5, Y3")
			w("\tVPSHUFB\t%d(R11), Y2, Y5", 32*(2*j+1))
			w("\tVPMADDWD\tY4, Y5, Y4")
			w("\tVPADDD\tY3, Y7, Y7")
			w("\tVPADDD\tY4, Y7, Y7")
		}
		w("\tVCVTDQ2PS\tY7, Y7")
		w("\tVFMADD231PS\tY7, Y6, Y0")
		w("\tADDQ\t$%d, SI", q4_KBlockBytes)
		w("\tADDQ\t$%d, DX", q8_KBlockBytes)
		w("\tDECQ\tCX")
		w("\tJNZ\tq4kblk%s", sfx)
		w("q4kred%s:", sfx)
		x64Hsum8Store(w, true)
	}
	x64NrcDispatch(w, wide, 8, q4_KBlockBytes, q8_KBlockBytes, "q4k", once, body)
	return sb.String()
}

// x64VecDotQ6_KKernel: q6_K x q8_K on AVX2 (see a64VecDotQ6_KKernel).
func x64VecDotQ6_KKernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	w := func(format string, args ...any) { fmt.Fprintf(&sb, format+"\n", args...) }
	cSym := pool.addBlob(x64QuantConsts())
	w("// %s: q6_K x q8_K dot (AVX2); nrc == 2 runs the four dots of the tile.", sym)
	once := func() {
		w("\tVMOVDQU\t·%s+%d(SB), Y8", cSym, x64qcLow)
		w("\tVMOVDQU\t·%s+%d(SB), Y9", cSym, x64qcM3)
		w("\tVMOVDQU\t·%s+%d(SB), Y10", cSym, x64qcM12)
		w("\tVMOVDQU\t·%s+%d(SB), Y11", cSym, x64qcM48)
		w("\tVMOVDQU\t·%s+%d(SB), Y12", cSym, x64qcM192)
		w("\tLEAQ\t·%s+%d(SB), R11", cSym, x64qcScale)
	}
	body := func(sfx string) {
		w("\tVXORPS\tY0, Y0, Y0")
		w("\tTESTQ\tCX, CX")
		w("\tJZ\tq6kred%s", sfx)
		w("q6kblk%s:", sfx)
		// scales (16 x i8) -> X2; q8sclsub = madd(bsums, scales_16) << 5 -> Y13
		w("\tVMOVDQU\t192(SI), X2")
		w("\tVPMOVSXBW\tX2, Y13")
		w("\tVPMADDWD\t260(DX), Y13, Y13")
		w("\tVPSLLD\t$5, Y13, Y13")
		w("\tVPXOR\tY7, Y7, Y7") // sumi
		for j := 0; j < 2; j++ {
			w("\tVMOVDQU\t%d(SI), Y3", 64*j)     // q4bits1
			w("\tVMOVDQU\t%d(SI), Y4", 64*j+32)  // q4bits2
			w("\tVMOVDQU\t%d(SI), Y5", 128+32*j) // q4bitsH
			w("\tVPAND\tY9, Y5, Y14")            // H & 3
			w("\tVPSLLW\t$4, Y14, Y14")          // q4h_0
			w("\tVPAND\tY10, Y5, Y15")           // H & 12
			w("\tVPSLLW\t$2, Y15, Y15")          // q4h_1
			w("\tVPAND\tY8, Y3, Y6")             // bits1 & 15
			w("\tVPOR\tY14, Y6, Y6")             // q4_0
			w("\tVPMADDUBSW\t%d(DX), Y6, Y6", 4+128*j)
			w("\tVPMOVSXBW\t%d(R11), Y14", 16*(4*j))
			w("\tVPMADDWD\tY6, Y14, Y6")
			w("\tVPADDD\tY6, Y7, Y7")
			w("\tVPAND\tY8, Y4, Y6") // bits2 & 15
			w("\tVPOR\tY15, Y6, Y6") // q4_1
			w("\tVPMADDUBSW\t%d(DX), Y6, Y6", 4+128*j+32)
			w("\tVPMOVSXBW\t%d(R11), Y14", 16*(4*j+1))
			w("\tVPMADDWD\tY6, Y14, Y6")
			w("\tVPADDD\tY6, Y7, Y7")
			w("\tVPAND\tY11, Y5, Y14")  // H & 48 = q4h_2
			w("\tVPAND\tY12, Y5, Y15")  // H & 0xc0
			w("\tVPSRLW\t$2, Y15, Y15") // q4h_3
			w("\tVPSRLW\t$4, Y3, Y6")
			w("\tVPAND\tY8, Y6, Y6")
			w("\tVPOR\tY14, Y6, Y6") // q4_2
			w("\tVPMADDUBSW\t%d(DX), Y6, Y6", 4+128*j+64)
			w("\tVPMOVSXBW\t%d(R11), Y14", 16*(4*j+2))
			w("\tVPMADDWD\tY6, Y14, Y6")
			w("\tVPADDD\tY6, Y7, Y7")
			w("\tVPSRLW\t$4, Y4, Y6")
			w("\tVPAND\tY8, Y6, Y6")
			w("\tVPOR\tY15, Y6, Y6") // q4_3
			w("\tVPMADDUBSW\t%d(DX), Y6, Y6", 4+128*j+96)
			w("\tVPMOVSXBW\t%d(R11), Y14", 16*(4*j+3))
			w("\tVPMADDWD\tY6, Y14, Y6")
			w("\tVPADDD\tY6, Y7, Y7")
		}
		w("\tVPSUBD\tY13, Y7, Y7")
		w("\tVCVTDQ2PS\tY7, Y7")
		// d = y.d * f16(x.d)
		x64F16Scalar(w, "SI", 208, 6)
		w("\tVMULSS\t(DX), X6, X6")
		w("\tVBROADCASTSS\tX6, Y6")
		w("\tVFMADD231PS\tY7, Y6, Y0")
		w("\tADDQ\t$%d, SI", q6_KBlockBytes)
		w("\tADDQ\t$%d, DX", q8_KBlockBytes)
		w("\tDECQ\tCX")
		w("\tJNZ\tq6kblk%s", sfx)
		w("q6kred%s:", sfx)
		x64Hsum8Store(w, false)
	}
	x64NrcDispatch(w, wide, 8, q6_KBlockBytes, q8_KBlockBytes, "q6k", once, body)
	return sb.String()
}
