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
	c := make([]byte, 992)
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
	fill(672, 0x01) // q5_K fifth bits, low nibbles
	fill(704, 0x02) // high nibbles
	fill(736, 32)   // q3_K scale centring
	fill(800, 0x10) // q5_1 fifth bit
	for i := 0; i < 32; i++ {
		c[768+i] = byte(kvaluesIQ4NL[i%16]) // iq4_nl table (signed), both lanes
		c[832+i] = byte(kvaluesFP4[i%16])   // mxfp4 table (signed), both lanes
		c[896+i] = byte(i / 8)              // VPSHUFB index spreading 4 sign bytes over 8-lane groups
		c[928+i] = 1 << (i % 8)             // kmask 1,2,..,128 x4
		c[960+i] = byte(i / 16)             // VPSHUFB index spreading 2 bytes over 16-lane halves
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
	x64qcLow     = 0
	x64qcHigh    = 32
	x64qcOnes    = 64
	x64qcBits    = 96
	x64qcBitM    = 128
	x64qcM3      = 160
	x64qcM12     = 192
	x64qcM48     = 224
	x64qcM192    = 256
	x64qcK4      = 288
	x64qcScale   = 544
	x64qcB1      = 672
	x64qcB2      = 704
	x64qcM32     = 736
	x64qcNL      = 768
	x64qcM16     = 800
	x64qcFP4     = 832
	x64qcSpread  = 896
	x64qcKmask   = 928
	x64qcSpread2 = 960
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

// x64VecDotQ5_KKernel: q5_K x q8_K on AVX2 (see a64VecDotQ5_KKernel).
func x64VecDotQ5_KKernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	w := func(format string, args ...any) { fmt.Fprintf(&sb, format+"\n", args...) }
	cSym := pool.addBlob(x64QuantConsts())
	w("// %s: q5_K x q8_K dot (AVX2); nrc == 2 runs the four dots of the tile.", sym)
	once := func() {
		w("\tVMOVDQU\t·%s+%d(SB), Y8", cSym, x64qcLow)
		w("\tLEAQ\t·%s+%d(SB), R11", cSym, x64qcK4)
	}
	body := func(sfx string) {
		w("\tVXORPS\tY0, Y0, Y0")
		w("\tVXORPS\tX1, X1, X1")
		w("\tTESTQ\tCX, CX")
		w("\tJZ\tq5kred%s", sfx)
		w("q5kblk%s:", sfx)
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
		w("\tVPXOR\tY7, Y7, Y7")   // sumi
		w("\tVMOVDQU\t16(SI), Y9") // qh: bits 2j / 2j+1 for sub-blocks 2j / 2j+1
		for j := 0; j < 4; j++ {
			w("\tVMOVDQU\t%d(SI), Y3", 48+32*j)
			w("\tVPSRLW\t$4, Y3, Y4")
			w("\tVPAND\tY8, Y3, Y3")
			w("\tVPAND\tY8, Y4, Y4")
			if j > 0 {
				w("\tVPSRLW\t$%d, Y9, Y10", 2*j)
			} else {
				w("\tVMOVDQA\tY9, Y10")
			}
			w("\tVPAND\t·%s+%d(SB), Y10, Y13", cSym, x64qcB1)
			w("\tVPSLLW\t$4, Y13, Y13")
			w("\tVPOR\tY13, Y3, Y3")
			w("\tVPAND\t·%s+%d(SB), Y10, Y13", cSym, x64qcB2)
			w("\tVPSLLW\t$3, Y13, Y13")
			w("\tVPOR\tY13, Y4, Y4")
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
		w("\tADDQ\t$%d, SI", q5_KBlockBytes)
		w("\tADDQ\t$%d, DX", q8_KBlockBytes)
		w("\tDECQ\tCX")
		w("\tJNZ\tq5kblk%s", sfx)
		w("q5kred%s:", sfx)
		x64Hsum8Store(w, true)
	}
	x64NrcDispatch(w, wide, 8, q5_KBlockBytes, q8_KBlockBytes, "q5k", once, body)
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
		// scales (16 x i8) -> X2 (kept: each group's scale pair is a
		// VPSHUFB of it); q8sclsub = madd(bsums, scales_16) << 5 -> Y13
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
			w("\tVPSHUFB\t%d(R11), X2, X14", 16*(4*j))
			w("\tVPMOVSXBW\tX14, Y14")
			w("\tVPMADDWD\tY6, Y14, Y6")
			w("\tVPADDD\tY6, Y7, Y7")
			w("\tVPAND\tY8, Y4, Y6") // bits2 & 15
			w("\tVPOR\tY15, Y6, Y6") // q4_1
			w("\tVPMADDUBSW\t%d(DX), Y6, Y6", 4+128*j+32)
			w("\tVPSHUFB\t%d(R11), X2, X14", 16*(4*j+1))
			w("\tVPMOVSXBW\tX14, Y14")
			w("\tVPMADDWD\tY6, Y14, Y6")
			w("\tVPADDD\tY6, Y7, Y7")
			w("\tVPAND\tY11, Y5, Y14")  // H & 48 = q4h_2
			w("\tVPAND\tY12, Y5, Y15")  // H & 0xc0
			w("\tVPSRLW\t$2, Y15, Y15") // q4h_3
			w("\tVPSRLW\t$4, Y3, Y6")
			w("\tVPAND\tY8, Y6, Y6")
			w("\tVPOR\tY14, Y6, Y6") // q4_2
			w("\tVPMADDUBSW\t%d(DX), Y6, Y6", 4+128*j+64)
			w("\tVPSHUFB\t%d(R11), X2, X14", 16*(4*j+2))
			w("\tVPMOVSXBW\tX14, Y14")
			w("\tVPMADDWD\tY6, Y14, Y6")
			w("\tVPADDD\tY6, Y7, Y7")
			w("\tVPSRLW\t$4, Y4, Y6")
			w("\tVPAND\tY8, Y6, Y6")
			w("\tVPOR\tY15, Y6, Y6") // q4_3
			w("\tVPMADDUBSW\t%d(DX), Y6, Y6", 4+128*j+96)
			w("\tVPSHUFB\t%d(R11), X2, X14", 16*(4*j+3))
			w("\tVPMOVSXBW\tX14, Y14")
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

// x64VecDotQ2_KKernel: q2_K x q8_K on AVX2 (see a64VecDotQ2_KKernel).
// X2 the 16 scale bytes (low nibbles), Y7 sumi, Y8 = 0x0f, Y9 = 0x03, R11
// the sub-block scale shuffle tables (x64qcScale).
func x64VecDotQ2_KKernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	w := func(format string, args ...any) { fmt.Fprintf(&sb, format+"\n", args...) }
	cSym := pool.addBlob(x64QuantConsts())
	w("// %s: q2_K x q8_K dot (AVX2).", sym)
	once := func() {
		w("\tVMOVDQU\t·%s+%d(SB), Y8", cSym, x64qcLow)
		w("\tVMOVDQU\t·%s+%d(SB), Y9", cSym, x64qcM3)
		w("\tLEAQ\t·%s+%d(SB), R11", cSym, x64qcScale)
	}
	body := func(sfx string) {
		w("\tVXORPS\tY0, Y0, Y0")
		w("\tTESTQ\tCX, CX")
		w("\tJZ\tq2kred%s", sfx)
		w("q2kblk%s:", sfx)
		// scales (low nibbles) -> X2; mins (high nibbles) -> 16 x i16 -> mins term
		w("\tVMOVDQU\t(SI), X2")
		w("\tVPSRLW\t$4, X2, X3")
		w("\tVPAND\tX8, X3, X3")
		w("\tVPAND\tX8, X2, X2")
		w("\tVPMOVZXBW\tX3, Y13")
		w("\tVPMADDWD\t260(DX), Y13, Y13")
		w("\tVCVTDQ2PS\tY13, Y13")
		// dmin = y.d * f16(x.dmin); sumf -= dmin * mins-term
		x64F16Scalar(w, "SI", 82, 6)
		w("\tVMULSS\t(DX), X6, X6")
		w("\tVBROADCASTSS\tX6, Y6")
		w("\tVFNMADD231PS\tY13, Y6, Y0")
		w("\tVPXOR\tY7, Y7, Y7") // sumi
		for j := 0; j < 2; j++ {
			w("\tVMOVDQU\t%d(SI), Y3", 16+32*j)
			for s := 0; s < 4; s++ {
				if s == 0 {
					w("\tVPAND\tY9, Y3, Y4")
				} else {
					w("\tVPSRLW\t$%d, Y3, Y4", 2*s)
					w("\tVPAND\tY9, Y4, Y4")
				}
				w("\tVPMADDUBSW\t%d(DX), Y4, Y4", 4+128*j+32*s)
				w("\tVPSHUFB\t%d(R11), X2, X14", 16*(4*j+s))
				w("\tVPMOVZXBW\tX14, Y14")
				w("\tVPMADDWD\tY4, Y14, Y4")
				w("\tVPADDD\tY4, Y7, Y7")
			}
		}
		w("\tVCVTDQ2PS\tY7, Y7")
		// d = y.d * f16(x.d)
		x64F16Scalar(w, "SI", 80, 6)
		w("\tVMULSS\t(DX), X6, X6")
		w("\tVBROADCASTSS\tX6, Y6")
		w("\tVFMADD231PS\tY7, Y6, Y0")
		w("\tADDQ\t$%d, SI", q2_KBlockBytes)
		w("\tADDQ\t$%d, DX", q8_KBlockBytes)
		w("\tDECQ\tCX")
		w("\tJNZ\tq2kblk%s", sfx)
		w("q2kred%s:", sfx)
		x64Hsum8Store(w, false)
	}
	x64NrcDispatch(w, wide, 8, q2_KBlockBytes, q8_KBlockBytes, "q2k", once, body)
	return sb.String()
}

// x64VecDotQ3_KKernel: q3_K x q8_K on AVX2 (see a64VecDotQ3_KKernel).
// X2 the 16 centred scale bytes, Y5 the hmask, Y7 sumi, Y13 the bias,
// Y8 = 0x0f (unused here but the shared prologue loads it), Y9 = 0x03,
// R11 the sub-block scale shuffle tables (x64qcScale); the scale decode
// uses R9, R10, R12, R13, BX.
func x64VecDotQ3_KKernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	w := func(format string, args ...any) { fmt.Fprintf(&sb, format+"\n", args...) }
	cSym := pool.addBlob(x64QuantConsts())
	w("// %s: q3_K x q8_K dot (AVX2).", sym)
	once := func() {
		w("\tVMOVDQU\t·%s+%d(SB), Y9", cSym, x64qcM3)
		w("\tLEAQ\t·%s+%d(SB), R11", cSym, x64qcScale)
	}
	body := func(sfx string) {
		w("\tVXORPS\tY0, Y0, Y0")
		w("\tTESTQ\tCX, CX")
		w("\tJZ\tq3kred%s", sfx)
		w("q3kblk%s:", sfx)
		// aux0/1/2 -> utmp0..3 (kmask1 = 0x03030303, kmask2 = 0x0f0f0f0f)
		w("\tMOVL\t96(SI), R9")   // aux0
		w("\tMOVL\t100(SI), R10") // aux1
		w("\tMOVL\t104(SI), R12") // aux2
		// utmp0 = (aux0 & kmask2) | ((aux2 & kmask1) << 4)
		w("\tMOVL\tR9, R13")
		w("\tANDL\t$0x0f0f0f0f, R13")
		w("\tMOVL\tR12, BX")
		w("\tANDL\t$0x03030303, BX")
		w("\tSHLL\t$4, BX")
		w("\tORL\tBX, R13")
		w("\tVMOVD\tR13, X2")
		// utmp1 = (aux1 & kmask2) | (((aux2 >> 2) & kmask1) << 4)
		w("\tMOVL\tR10, R13")
		w("\tANDL\t$0x0f0f0f0f, R13")
		w("\tMOVL\tR12, BX")
		w("\tSHRL\t$2, BX")
		w("\tANDL\t$0x03030303, BX")
		w("\tSHLL\t$4, BX")
		w("\tORL\tBX, R13")
		w("\tVPINSRD\t$1, R13, X2, X2")
		// utmp2 = ((aux0 >> 4) & kmask2) | (((aux2 >> 4) & kmask1) << 4)
		w("\tMOVL\tR9, R13")
		w("\tSHRL\t$4, R13")
		w("\tANDL\t$0x0f0f0f0f, R13")
		w("\tMOVL\tR12, BX")
		w("\tSHRL\t$4, BX")
		w("\tANDL\t$0x03030303, BX")
		w("\tSHLL\t$4, BX")
		w("\tORL\tBX, R13")
		w("\tVPINSRD\t$2, R13, X2, X2")
		// utmp3 = ((aux1 >> 4) & kmask2) | (((aux2 >> 6) & kmask1) << 4)
		w("\tMOVL\tR10, R13")
		w("\tSHRL\t$4, R13")
		w("\tANDL\t$0x0f0f0f0f, R13")
		w("\tMOVL\tR12, BX")
		w("\tSHRL\t$6, BX")
		w("\tANDL\t$0x03030303, BX")
		w("\tSHLL\t$4, BX")
		w("\tORL\tBX, R13")
		w("\tVPINSRD\t$3, R13, X2, X2")
		w("\tVPSUBB\t·%s+%d(SB), X2, X2", cSym, x64qcM32) // centre
		// bias = 4 * sum(sc * bsums) -> Y13
		w("\tVPMOVSXBW\tX2, Y13")
		w("\tVPMADDWD\t260(DX), Y13, Y13")
		w("\tVPSLLD\t$2, Y13, Y13")
		w("\tVMOVDQU\t(SI), Y5") // hmask
		w("\tVPXOR\tY7, Y7, Y7") // sumi
		for j := 0; j < 2; j++ {
			w("\tVMOVDQU\t%d(SI), Y3", 32+32*j)
			for s := 0; s < 4; s++ {
				if s == 0 {
					w("\tVPAND\tY9, Y3, Y4")
				} else {
					w("\tVPSRLW\t$%d, Y3, Y4", 2*s)
					w("\tVPAND\tY9, Y4, Y4")
				}
				// third bit: hmask bit 4j+s
				k := 4*j + s
				if k == 0 {
					w("\tVPAND\t·%s+%d(SB), Y5, Y14", cSym, x64qcB1)
				} else {
					w("\tVPSRLW\t$%d, Y5, Y14", k)
					w("\tVPAND\t·%s+%d(SB), Y14, Y14", cSym, x64qcB1)
				}
				w("\tVPSLLW\t$2, Y14, Y14")
				w("\tVPOR\tY14, Y4, Y4")
				w("\tVPMADDUBSW\t%d(DX), Y4, Y4", 4+128*j+32*s)
				w("\tVPSHUFB\t%d(R11), X2, X14", 16*(4*j+s))
				w("\tVPMOVSXBW\tX14, Y14")
				w("\tVPMADDWD\tY4, Y14, Y4")
				w("\tVPADDD\tY4, Y7, Y7")
			}
		}
		w("\tVPSUBD\tY13, Y7, Y7")
		w("\tVCVTDQ2PS\tY7, Y7")
		// d = y.d * f16(x.d)
		x64F16Scalar(w, "SI", 108, 6)
		w("\tVMULSS\t(DX), X6, X6")
		w("\tVBROADCASTSS\tX6, Y6")
		w("\tVFMADD231PS\tY7, Y6, Y0")
		w("\tADDQ\t$%d, SI", q3_KBlockBytes)
		w("\tADDQ\t$%d, DX", q8_KBlockBytes)
		w("\tDECQ\tCX")
		w("\tJNZ\tq3kblk%s", sfx)
		w("q3kred%s:", sfx)
		x64Hsum8Store(w, false)
	}
	x64NrcDispatch(w, wide, 8, q3_KBlockBytes, q8_KBlockBytes, "q3k", once, body)
	return sb.String()
}

// x64VecDotIQ4NLKernel: iq4_nl x q8_0 on AVX2 (see a64VecDotIQ4NLKernel):
// nibbles through the kvalues table (VPSHUFB), then the sign-trick u8 x s8
// pair dot.
func x64VecDotIQ4NLKernel(sym string, pool *ConstPool, wide bool) string {
	return x64VecDotLUT32(sym, pool, wide, lut32IQ4NL)
}

// x64VecDotMXFP4Kernel: mxfp4 x q8_0 on AVX2, the same body with the fp4
// table and an E8M0 block scale.
func x64VecDotMXFP4Kernel(sym string, pool *ConstPool, wide bool) string {
	return x64VecDotLUT32(sym, pool, wide, lut32MXFP4)
}

func x64VecDotLUT32(sym string, pool *ConstPool, wide bool, L lut32Layout) string {
	var sb strings.Builder
	w := func(format string, args ...any) { fmt.Fprintf(&sb, format+"\n", args...) }
	cSym := pool.addBlob(x64QuantConsts())
	tbl := x64qcNL
	if L.e8m0 {
		tbl = x64qcFP4
	}
	w("// %s: %s x q8_0 dot (AVX2).", sym, L.name)
	w("\tVXORPS\tY0, Y0, Y0")
	x64VecDotPrologue(w, wide, 5, L.blockBytes, q8_0BlockBytes, L.lbl+"oob", L.lbl+"reduce")
	w("\tVMOVDQU\t·%s+%d(SB), Y8", cSym, x64qcLow)
	w("\tVMOVDQU\t·%s+%d(SB), Y10", cSym, x64qcOnes)
	w("\tVMOVDQU\t·%s+%d(SB), Y11", cSym, tbl)
	w("%sblk:", L.lbl)
	// qx = table[bytes_from_nibbles_32(qs)]
	w("\tVMOVDQU\t%d(SI), X2", L.qsOff)
	w("\tVPSRLW\t$4, X2, X3")
	w("\tVINSERTI128\t$1, X3, Y2, Y2")
	w("\tVPAND\tY8, Y2, Y2")
	w("\tVPSHUFB\tY2, Y11, Y2")
	// mul_sum_i8_pairs: ax = |qx|, sy = sign(qy, qx)
	w("\tVMOVDQU\t2(DX), Y4")
	w("\tVPSIGNB\tY2, Y2, Y5")
	w("\tVPSIGNB\tY2, Y4, Y4")
	w("\tVPMADDUBSW\tY4, Y5, Y5")
	w("\tVPMADDWD\tY10, Y5, Y5")
	w("\tVCVTDQ2PS\tY5, Y5")
	if L.e8m0 {
		x64E8M0Half(w, "SI", 0, 6)
	} else {
		x64F16Scalar(w, "SI", 0, 6)
	}
	x64F16Scalar(w, "DX", 0, 7)
	w("\tVMULSS\tX7, X6, X6")
	w("\tVBROADCASTSS\tX6, Y6")
	w("\tVFMADD231PS\tY5, Y6, Y0")
	w("\tADDQ\t$%d, SI", L.blockBytes)
	w("\tADDQ\t$%d, DX", q8_0BlockBytes)
	w("\tDECQ\tCX")
	w("\tJNZ\t%sblk", L.lbl)
	w("%sreduce:", L.lbl)
	x64Hsum8Store(w, false)
	w("\tVZEROUPPER")
	w("\tRET")
	w("%soob:", L.lbl)
	w("\tVZEROUPPER")
	w("\tJMP\tovr_oob")
	return sb.String()
}

// x64E8M0Half loads the E8M0 byte at off(reg) and leaves
// ggml_e8m0_to_fp32_half of it (2^(e-128), denormal for e < 2) in X<dst>:
// bits = e >= 2 ? (e-1) << 23 : 0x00200000 << e. R9-R11 are scratch.
func x64E8M0Half(w func(string, ...any), reg string, off, dst int) {
	w("\tMOVBLZX\t%d(%s), R9", off, reg)
	w("\tLEAL\t-1(R9), R10")
	w("\tSHLL\t$23, R10")
	w("\tIMUL3L\t$0x00200000, R9, R11") // 0x00200000 << e for e in {0, 1}
	w("\tADDL\t$0x00200000, R11")
	w("\tCMPL\tR9, $2")
	w("\tCMOVLCS\tR11, R10") // e < 2: the denormal pattern
	w("\tVMOVD\tR10, X%d", dst)
}

// x64VecDotIQ4XSKernel: iq4_xs x q8_K on AVX2 (see a64VecDotIQ4XSKernel):
// per 32-quant sub-block the kvalues lookup and sign-trick pair dot give
// eight i32 lanes, multiplied by the sub-block's 6-bit scale and summed
// over the super-block in i32; the block's f16 d times the activation
// block's f32 d scales the total once.
func x64VecDotIQ4XSKernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	w := func(format string, args ...any) { fmt.Fprintf(&sb, format+"\n", args...) }
	cSym := pool.addBlob(x64QuantConsts())
	w("// %s: iq4_xs x q8_K dot (AVX2).", sym)
	w("\tVXORPS\tY0, Y0, Y0")
	x64VecDotPrologue(w, wide, 8, iq4_xsBlockBytes, q8_KBlockBytes, "ixoob", "ixreduce")
	w("\tVMOVDQU\t·%s+%d(SB), Y8", cSym, x64qcLow)
	w("\tVMOVDQU\t·%s+%d(SB), Y10", cSym, x64qcOnes)
	w("\tVMOVDQU\t·%s+%d(SB), Y11", cSym, x64qcNL)
	w("ixblk:")
	w("\tVPXOR\tY1, Y1, Y1")   // i32 super-block sum
	w("\tMOVWLZX\t2(SI), R12") // scales_h
	w("\tMOVL\t4(SI), R13")    // scales_l
	for ib := 0; ib < 8; ib++ {
		w("\tVMOVDQU\t%d(SI), X2", 8+16*ib)
		w("\tVPSRLW\t$4, X2, X3")
		w("\tVINSERTI128\t$1, X3, Y2, Y2")
		w("\tVPAND\tY8, Y2, Y2")
		w("\tVPSHUFB\tY2, Y11, Y2")
		w("\tVMOVDQU\t%d(DX), Y4", 4+32*ib)
		w("\tVPSIGNB\tY2, Y2, Y5")
		w("\tVPSIGNB\tY2, Y4, Y4")
		w("\tVPMADDUBSW\tY4, Y5, Y5")
		w("\tVPMADDWD\tY10, Y5, Y5")
		// ls = (scales_l nibble | (scales_h bits) << 4) - 32
		if ib%2 == 0 {
			w("\tMOVL\tR13, R10")
			w("\tANDL\t$0xf, R10")
			w("\tMOVL\tR12, R11")
			w("\tSHLL\t$4, R11")
		} else {
			w("\tMOVL\tR13, R10")
			w("\tSHRL\t$4, R10")
			w("\tANDL\t$0xf, R10")
			w("\tMOVL\tR12, R11")
			w("\tSHLL\t$2, R11")
		}
		w("\tANDL\t$0x30, R11")
		w("\tORL\tR11, R10")
		w("\tSUBL\t$32, R10")
		w("\tVMOVD\tR10, X6")
		w("\tVPBROADCASTD\tX6, Y6")
		w("\tVPMULLD\tY6, Y5, Y5")
		w("\tVPADDD\tY5, Y1, Y1")
		if ib%2 == 1 && ib < 7 {
			w("\tSHRL\t$4, R12")
			w("\tSHRL\t$8, R13")
		}
	}
	w("\tVCVTDQ2PS\tY1, Y1")
	x64F16Scalar(w, "SI", 0, 6)
	w("\tVMOVSS\t0(DX), X7")
	w("\tVMULSS\tX7, X6, X6")
	w("\tVBROADCASTSS\tX6, Y6")
	w("\tVFMADD231PS\tY1, Y6, Y0")
	w("\tADDQ\t$%d, SI", iq4_xsBlockBytes)
	w("\tADDQ\t$%d, DX", q8_KBlockBytes)
	w("\tDECQ\tCX")
	w("\tJNZ\tixblk")
	w("ixreduce:")
	x64Hsum8Store(w, false)
	w("\tVZEROUPPER")
	w("\tRET")
	w("ixoob:")
	w("\tVZEROUPPER")
	w("\tJMP\tovr_oob")
	return sb.String()
}

// x64VecDotQ5_1Kernel / x64VecDotQ4_1Kernel: q5_1 / q4_1 x q8_1 on AVX2
// (see a64VecDotQ5_1Kernel): the quants stay unsigned (0..31 / 0..15), so
// VPMADDUBSW takes them directly against the signed activations; the min
// term m * s accumulates in X1 and joins at the reduction.
func x64VecDotQ5_1Kernel(sym string, pool *ConstPool, wide bool) string {
	return x64VecDotQx1Kernel(sym, pool, wide, true)
}

func x64VecDotQ4_1Kernel(sym string, pool *ConstPool, wide bool) string {
	return x64VecDotQx1Kernel(sym, pool, wide, false)
}

func x64VecDotQx1Kernel(sym string, pool *ConstPool, wide bool, fifth bool) string {
	var sb strings.Builder
	w := func(format string, args ...any) { fmt.Fprintf(&sb, format+"\n", args...) }
	cSym := pool.addBlob(x64QuantConsts())
	name, lbl, xBlock, qsOff := "q4_1", "q41", q4_1BlockBytes, 4
	if fifth {
		name, lbl, xBlock, qsOff = "q5_1", "q51", q5_1BlockBytes, 8
	}
	w("// %s: %s x q8_1 dot (AVX2).", sym, name)
	w("\tVXORPS\tY0, Y0, Y0")
	w("\tVXORPS\tX1, X1, X1")
	x64VecDotPrologue(w, wide, 5, xBlock, q8_1BlockBytes, lbl+"oob", lbl+"reduce")
	w("\tVMOVDQU\t·%s+%d(SB), Y8", cSym, x64qcLow)
	w("\tVMOVDQU\t·%s+%d(SB), Y10", cSym, x64qcOnes)
	if fifth {
		w("\tVMOVDQU\t·%s+%d(SB), Y11", cSym, x64qcBits)
		w("\tVMOVDQU\t·%s+%d(SB), Y12", cSym, x64qcBitM)
		w("\tVPCMPEQB\tY13, Y13, Y13") // all ones
	}
	w("%sblk:", lbl)
	// qx = bytes_from_nibbles_32(qs)
	w("\tVMOVDQU\t%d(SI), X2", qsOff)
	w("\tVPSRLW\t$4, X2, X3")
	w("\tVINSERTI128\t$1, X3, Y2, Y2")
	w("\tVPAND\tY8, Y2, Y2")
	if fifth {
		// qx |= 0x10 where the fifth bit is set
		w("\tVPBROADCASTD\t4(SI), Y3")
		w("\tVPSHUFB\tY11, Y3, Y3")
		w("\tVPOR\tY12, Y3, Y3")
		w("\tVPCMPEQB\tY13, Y3, Y3")
		w("\tVPAND\t·%s+%d(SB), Y3, Y3", cSym, x64qcM16)
		w("\tVPOR\tY3, Y2, Y2")
	}
	// unsigned quants x signed activations
	w("\tVMOVDQU\t4(DX), Y4")
	w("\tVPMADDUBSW\tY4, Y2, Y5")
	w("\tVPMADDWD\tY10, Y5, Y5")
	w("\tVCVTDQ2PS\tY5, Y5")
	// d = f16(x.d) * f16(y.d)
	x64F16Scalar(w, "SI", 0, 6)
	x64F16Scalar(w, "DX", 0, 7)
	w("\tVMULSS\tX7, X6, X6")
	w("\tVBROADCASTSS\tX6, Y6")
	w("\tVFMADD231PS\tY5, Y6, Y0")
	// min term: m * s
	x64F16Scalar(w, "SI", 2, 6)
	x64F16Scalar(w, "DX", 2, 7)
	w("\tVMULSS\tX7, X6, X6")
	w("\tVADDSS\tX6, X1, X1")
	w("\tADDQ\t$%d, SI", xBlock)
	w("\tADDQ\t$%d, DX", q8_1BlockBytes)
	w("\tDECQ\tCX")
	w("\tJNZ\t%sblk", lbl)
	w("%sreduce:", lbl)
	x64Hsum8Store(w, true)
	w("\tVZEROUPPER")
	w("\tRET")
	w("%soob:", lbl)
	w("\tVZEROUPPER")
	w("\tJMP\tovr_oob")
	return sb.String()
}

// x64VecDotQ4_0Kernel: q4_0 x q8_0 on AVX2 (see a64VecDotQ4_0Kernel).
// Per block: nibbles to bytes minus 8, then the sign-trick u8 x s8 pair
// dot of x64VecDotQ5_0Kernel.
func x64VecDotQ4_0Kernel(sym string, pool *ConstPool, wide bool) string {
	return x64VecDotLegacy(sym, pool, wide, "q4_0", q4_0BlockBytes)
}

// x64VecDotQ8_0Kernel: q8_0 x q8_0 on AVX2, the same pair dot on the
// stored bytes.
func x64VecDotQ8_0Kernel(sym string, pool *ConstPool, wide bool) string {
	return x64VecDotLegacy(sym, pool, wide, "q8_0", q8_0BlockBytes)
}

func x64VecDotLegacy(sym string, pool *ConstPool, wide bool, kind string, xBlock int) string {
	var sb strings.Builder
	w := func(format string, args ...any) { fmt.Fprintf(&sb, format+"\n", args...) }
	cSym := pool.addBlob(x64QuantConsts())
	lbl := "q4d"
	if kind == "q8_0" {
		lbl = "q8d"
	}
	w("// %s: %s x q8_0 dot (AVX2).", sym, kind)
	w("\tVXORPS\tY0, Y0, Y0")
	x64VecDotPrologue(w, wide, 5, xBlock, q8_0BlockBytes, lbl+"oob", lbl+"reduce")
	w("\tVMOVDQU\t·%s+%d(SB), Y10", cSym, x64qcOnes)
	if kind != "q8_0" {
		w("\tVMOVDQU\t·%s+%d(SB), Y8", cSym, x64qcLow)
		w("\tVMOVDQU\t·%s+%d(SB), Y9", cSym, x64qcM16)
		w("\tVPSRLW\t$1, Y9, Y9") // 0x10 >> 1 in every byte pair: 8
	}
	w("%sblk:", lbl)
	if kind == "q8_0" {
		w("\tVMOVDQU\t2(SI), Y2")
	} else {
		// qx = bytes_from_nibbles_32(qs) - 8
		w("\tVMOVDQU\t2(SI), X2")
		w("\tVPSRLW\t$4, X2, X3")
		w("\tVINSERTI128\t$1, X3, Y2, Y2")
		w("\tVPAND\tY8, Y2, Y2")
		w("\tVPSUBB\tY9, Y2, Y2")
	}
	// mul_sum_i8_pairs: ax = |qx|, sy = sign(qy, qx)
	w("\tVMOVDQU\t2(DX), Y4")
	w("\tVPSIGNB\tY2, Y2, Y5")
	w("\tVPSIGNB\tY2, Y4, Y4")
	w("\tVPMADDUBSW\tY4, Y5, Y5")
	w("\tVPMADDWD\tY10, Y5, Y5")
	w("\tVCVTDQ2PS\tY5, Y5")
	x64F16Scalar(w, "SI", 0, 6)
	x64F16Scalar(w, "DX", 0, 7)
	w("\tVMULSS\tX7, X6, X6")
	w("\tVBROADCASTSS\tX6, Y6")
	w("\tVFMADD231PS\tY5, Y6, Y0")
	w("\tADDQ\t$%d, SI", xBlock)
	w("\tADDQ\t$%d, DX", q8_0BlockBytes)
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

// x64VecDotIQ3XXSKernel / x64VecDotIQ3SKernel: the iq3 dots on AVX2 (see
// vecdot_iq3_a64.go). The 32 magnitudes of a sub-block are gathered as
// eight grid words through VPINSRD, the signs land in Y4 as +-1 bytes
// (iq3_xxs: four u64 gathers from the keven table; iq3_s: the four sign
// bytes spread with VPSHUFB, tested against kmask, or'ed with 1) and are
// applied to the activation bytes with VPSIGNB so the unsigned magnitudes
// take the u8 side of VPMADDUBSW.
func x64VecDotIQ3XXSKernel(sym string, pool *ConstPool, wide bool) string {
	return x64VecDotIQ3(sym, pool, wide, false)
}

func x64VecDotIQ3SKernel(sym string, pool *ConstPool, wide bool) string {
	return x64VecDotIQ3(sym, pool, wide, true)
}

func x64VecDotIQ3(sym string, pool *ConstPool, wide bool, iq3s bool) string {
	var sb strings.Builder
	w := func(format string, args ...any) { fmt.Fprintf(&sb, format+"\n", args...) }
	cSym := pool.addBlob(x64QuantConsts())
	name, lbl, blockBytes := "iq3_xxs", "i3x", iq3_xxsBlockBytes
	grid := pool.addBlob(iq3xxsConsts())
	if iq3s {
		name, lbl, blockBytes = "iq3_s", "i3s", iq3_sBlockBytes
		grid = pool.addBlob(iq3sConsts())
	}
	w("// %s: %s x q8_K dot (AVX2), grid gathers through VPINSRD, signs applied to the activations.", sym, name)
	w("\tVXORPS\tY0, Y0, Y0")
	x64VecDotPrologue(w, wide, 8, blockBytes, q8_KBlockBytes, lbl+"oob", lbl+"reduce")
	w("\tMOVQ\t$·%s(SB), R12", grid)
	if !iq3s {
		w("\tLEAQ\t1024(R12), R13") // the keven sign table
	}
	w("\tVMOVDQU\t·%s+%d(SB), Y10", cSym, x64qcOnes)
	if iq3s {
		w("\tVMOVDQU\t·%s+%d(SB), Y11", cSym, x64qcSpread)
		w("\tVMOVDQU\t·%s+%d(SB), Y12", cSym, x64qcKmask)
		w("\tVMOVDQU\t·%s+%d(SB), Y13", cSym, x64qcB1)
	}
	w("%sblk:", lbl)
	w("\tVPXOR\tY1, Y1, Y1")
	for ib := 0; ib < 8; ib++ {
		if iq3s {
			w("\tMOVBLZX\t%d(SI), R10", 66+ib) // ninth index bits
		}
		for k := 0; k < 8; k++ {
			w("\tMOVBLZX\t%d(SI), R14", 2+8*ib+k)
			if iq3s {
				w("\tMOVL\tR10, R11")
				w("\tSHRL\t$%d, R11", k)
				w("\tANDL\t$1, R11")
				w("\tSHLL\t$8, R11")
				w("\tORL\tR11, R14")
			}
			w("\tMOVL\t(R12)(R14*4), R15")
			if k < 4 {
				w("\tVPINSRD\t$%d, R15, X2, X2", k)
			} else {
				w("\tVPINSRD\t$%d, R15, X5, X5", k-4)
			}
		}
		w("\tVINSERTI128\t$1, X5, Y2, Y2") // 32 magnitudes
		if iq3s {
			w("\tMOVL\t%d(SI), R9", 74+4*ib)
			w("\tVMOVD\tR9, X4")
			w("\tVPBROADCASTD\tX4, Y4")
			w("\tVPSHUFB\tY11, Y4, Y4") // [s0 x8 | s1 x8 | s2 x8 | s3 x8]
			w("\tVPAND\tY12, Y4, Y4")
			w("\tVPCMPEQB\tY12, Y4, Y4") // 0xff where the sign bit is set
			w("\tVPOR\tY13, Y4, Y4")     // -1 / +1
		} else {
			w("\tMOVL\t%d(SI), R9", 66+4*ib) // sign codes | scale
			for l := 0; l < 4; l++ {
				w("\tMOVL\tR9, R14")
				w("\tSHRL\t$%d, R14", 7*l)
				w("\tANDL\t$127, R14")
				w("\tMOVQ\t(R13)(R14*8), R15")
				if l < 2 {
					w("\tVPINSRQ\t$%d, R15, X4, X4", l)
				} else {
					w("\tVPINSRQ\t$%d, R15, X7, X7", l-2)
				}
			}
			w("\tVINSERTI128\t$1, X7, Y4, Y4")
		}
		w("\tVMOVDQU\t%d(DX), Y3", 4+32*ib)
		w("\tVPSIGNB\tY4, Y3, Y3") // activations signed by the quant signs
		w("\tVPMADDUBSW\tY3, Y2, Y5")
		w("\tVPMADDWD\tY10, Y5, Y5")
		if iq3s {
			w("\tMOVBLZX\t%d(SI), R8", 106+ib/2)
			if ib%2 == 0 {
				w("\tANDL\t$0xf, R8")
			} else {
				w("\tSHRL\t$4, R8")
			}
		} else {
			w("\tMOVL\tR9, R8")
			w("\tSHRL\t$28, R8")
		}
		w("\tLEAL\t1(R8)(R8*1), R8") // ls = 2*nibble + 1
		w("\tVMOVD\tR8, X6")
		w("\tVPBROADCASTD\tX6, Y6")
		w("\tVPMULLD\tY6, Y5, Y5")
		w("\tVPADDD\tY5, Y1, Y1")
	}
	w("\tVCVTDQ2PS\tY1, Y1")
	x64F16Scalar(w, "SI", 0, 6)
	w("\tVMOVSS\t0(DX), X7")
	w("\tVMULSS\tX7, X6, X6")
	if !iq3s {
		w("\tMOVL\t$0x3E800000, R8") // 0.25f
		w("\tVMOVD\tR8, X7")
		w("\tVMULSS\tX7, X6, X6")
	}
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

// x64VecDotIQ2XXSKernel / x64VecDotIQ2XSKernel / x64VecDotIQ2SKernel: the
// iq2 dots on AVX2 (see vecdot_iq2_a64.go): four u64 grid gathers per
// sub-block through VPINSRQ, signs as +-1 bytes applied to the activations
// with VPSIGNB, VPMADDUBSW/VPMADDWD into eight i32 lanes weighted by the
// per-16-quant scales [ls1 x4 | ls2 x4] (one scale for iq2_xxs).
func x64VecDotIQ2XXSKernel(sym string, pool *ConstPool, wide bool) string {
	return x64VecDotIQ2(sym, pool, wide, iq2xxsL)
}
func x64VecDotIQ2XSKernel(sym string, pool *ConstPool, wide bool) string {
	return x64VecDotIQ2(sym, pool, wide, iq2xsL)
}
func x64VecDotIQ2SKernel(sym string, pool *ConstPool, wide bool) string {
	return x64VecDotIQ2(sym, pool, wide, iq2sL)
}

func x64VecDotIQ2(sym string, pool *ConstPool, wide bool, L iq2Layout) string {
	var sb strings.Builder
	w := func(format string, args ...any) { fmt.Fprintf(&sb, format+"\n", args...) }
	cSym := pool.addBlob(x64QuantConsts())
	grid := pool.addBlob(iq2Consts(L))
	w("// %s: %s x q8_K dot (AVX2), u64 grid gathers through VPINSRQ, signs applied to the activations.", sym, L.name)
	w("\tVXORPS\tY0, Y0, Y0")
	x64VecDotPrologue(w, wide, 8, L.blockBytes, q8_KBlockBytes, L.lbl+"oob", L.lbl+"reduce")
	w("\tMOVQ\t$·%s(SB), R12", grid)
	w("\tLEAQ\t%d(R12), R13", L.gridBytes) // sign table / spread constants
	w("\tVMOVDQU\t·%s+%d(SB), Y10", cSym, x64qcOnes)
	if L.name == "iq2_s" {
		w("\tVMOVDQU\t·%s+%d(SB), Y11", cSym, x64qcSpread)
		w("\tVMOVDQU\t·%s+%d(SB), Y12", cSym, x64qcKmask)
		w("\tVMOVDQU\t·%s+%d(SB), Y13", cSym, x64qcB1)
	}
	w("%sblk:", L.lbl)
	w("\tVPXOR\tY1, Y1, Y1")
	for ib := 0; ib < 8; ib++ {
		switch L.name {
		case "iq2_xxs":
			w("\tMOVQ\t%d(SI), R9", 2+8*ib) // indices | codes | scale
			for l := 0; l < 4; l++ {
				w("\tMOVQ\tR9, R14")
				w("\tSHRQ\t$%d, R14", 8*l)
				w("\tANDL\t$0xff, R14")
				w("\tMOVQ\t(R12)(R14*8), R15")
				if l < 2 {
					w("\tVPINSRQ\t$%d, R15, X2, X2", l)
				} else {
					w("\tVPINSRQ\t$%d, R15, X5, X5", l-2)
				}
				w("\tMOVQ\tR9, R14")
				w("\tSHRQ\t$%d, R14", 32+7*l)
				w("\tANDL\t$127, R14")
				w("\tMOVQ\t(R13)(R14*8), R15")
				if l < 2 {
					w("\tVPINSRQ\t$%d, R15, X4, X4", l)
				} else {
					w("\tVPINSRQ\t$%d, R15, X7, X7", l-2)
				}
			}
			w("\tVINSERTI128\t$1, X7, Y4, Y4")
		case "iq2_xs":
			w("\tMOVQ\t%d(SI), R9", 2+8*ib) // four u16: index | code << 9
			for l := 0; l < 4; l++ {
				w("\tMOVQ\tR9, R14")
				w("\tSHRQ\t$%d, R14", 16*l)
				w("\tMOVL\tR14, R8")
				w("\tANDL\t$511, R14")
				w("\tMOVQ\t(R12)(R14*8), R15")
				if l < 2 {
					w("\tVPINSRQ\t$%d, R15, X2, X2", l)
				} else {
					w("\tVPINSRQ\t$%d, R15, X5, X5", l-2)
				}
				w("\tSHRL\t$9, R8")
				w("\tANDL\t$127, R8")
				w("\tMOVQ\t(R13)(R8*8), R15")
				if l < 2 {
					w("\tVPINSRQ\t$%d, R15, X4, X4", l)
				} else {
					w("\tVPINSRQ\t$%d, R15, X7, X7", l-2)
				}
			}
			w("\tVINSERTI128\t$1, X7, Y4, Y4")
		default: // iq2_s
			w("\tMOVBLZX\t%d(SI), R10", 66+ib) // two high index bits per group
			for l := 0; l < 4; l++ {
				w("\tMOVBLZX\t%d(SI), R14", 2+4*ib+l)
				w("\tMOVL\tR10, R11")
				w("\tSHRL\t$%d, R11", 2*l)
				w("\tANDL\t$3, R11")
				w("\tSHLL\t$8, R11")
				w("\tORL\tR11, R14")
				w("\tMOVQ\t(R12)(R14*8), R15")
				if l < 2 {
					w("\tVPINSRQ\t$%d, R15, X2, X2", l)
				} else {
					w("\tVPINSRQ\t$%d, R15, X5, X5", l-2)
				}
			}
			w("\tMOVL\t%d(SI), R9", 34+4*ib) // four sign bytes
			w("\tVMOVD\tR9, X4")
			w("\tVPBROADCASTD\tX4, Y4")
			w("\tVPSHUFB\tY11, Y4, Y4")
			w("\tVPAND\tY12, Y4, Y4")
			w("\tVPCMPEQB\tY12, Y4, Y4")
			w("\tVPOR\tY13, Y4, Y4")
		}
		w("\tVINSERTI128\t$1, X5, Y2, Y2") // 32 magnitudes
		w("\tVMOVDQU\t%d(DX), Y3", 4+32*ib)
		w("\tVPSIGNB\tY4, Y3, Y3")
		w("\tVPMADDUBSW\tY3, Y2, Y5")
		w("\tVPMADDWD\tY10, Y5, Y5")
		if L.twoScales {
			scOff := 66 + ib
			if L.name == "iq2_s" {
				scOff = 74 + ib
			}
			w("\tMOVBLZX\t%d(SI), R8", scOff)
			w("\tMOVL\tR8, R9")
			w("\tANDL\t$0xf, R8")
			w("\tSHRL\t$4, R9")
			w("\tLEAL\t1(R8)(R8*1), R8") // ls1
			w("\tLEAL\t1(R9)(R9*1), R9") // ls2
			w("\tVMOVD\tR8, X6")
			w("\tVMOVD\tR9, X7")
			w("\tVPBROADCASTD\tX6, X6")
			w("\tVPBROADCASTD\tX7, X7")
			w("\tVINSERTI128\t$1, X7, Y6, Y6") // [ls1 x4 | ls2 x4]
		} else {
			w("\tSHRQ\t$60, R9")
			w("\tLEAL\t1(R9)(R9*1), R9") // ls = 2*(aux >> 28) + 1
			w("\tVMOVD\tR9, X6")
			w("\tVPBROADCASTD\tX6, Y6")
		}
		w("\tVPMULLD\tY6, Y5, Y5")
		w("\tVPADDD\tY5, Y1, Y1")
	}
	w("\tVCVTDQ2PS\tY1, Y1")
	x64F16Scalar(w, "SI", 0, 6)
	w("\tVMOVSS\t0(DX), X7")
	w("\tVMULSS\tX7, X6, X6")
	w("\tMOVL\t$0x3E000000, R8") // 0.125f
	w("\tVMOVD\tR8, X7")
	w("\tVMULSS\tX7, X6, X6")
	w("\tVBROADCASTSS\tX6, Y6")
	w("\tVFMADD231PS\tY1, Y6, Y0")
	w("\tADDQ\t$%d, SI", L.blockBytes)
	w("\tADDQ\t$%d, DX", q8_KBlockBytes)
	w("\tDECQ\tCX")
	w("\tJNZ\t%sblk", L.lbl)
	w("%sreduce:", L.lbl)
	x64Hsum8Store(w, false)
	w("\tVZEROUPPER")
	w("\tRET")
	w("%soob:", L.lbl)
	w("\tVZEROUPPER")
	w("\tJMP\tovr_oob")
	return sb.String()
}
