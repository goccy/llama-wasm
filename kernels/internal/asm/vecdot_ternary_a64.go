package asm

import (
	"encoding/binary"
	"math"
	"strings"
)

// The remaining ggml-cpu dot formats: the ternary TQ1_0 / TQ2_0 (q8_K
// activations), the binary Q1_0 and 2-bit Q2_0, and NVFP4 (q8_0
// activations). None has a codebook; each decodes its quants into signed
// bytes and SDOTs them against the activations.
//
//   tq2_0: 256 quants as 64 bytes of 2-bit fields, plane l of chunk j
//          (bits 2l of bytes 32j..32j+31) is quants 128j + 32l .. +31, value
//          field - 1.
//   tq1_0: 240 quants as 48 bytes of five base-3 digits each (digit l of
//          byte m is ((byte * 3^l * 3) >> 8) - 1, mapping 32 bytes to 160
//          quants and the last 16 bytes to 80), plus 16 quants as four
//          base-3 digits of qh.
//   q1_0:  128 quants as 16 bytes of sign bits (set: +y, clear: -y), four
//          q8_0 activation blocks per block, each with its own scale.
//   q2_0:  64 quants as 16 bytes of 2-bit fields in element order (byte b
//          holds quants 4b..4b+3, low bits first), value field - 1, two
//          q8_0 blocks per block.
//   nvfp4: 64 quants as four 16-quant sub-blocks of fp4 nibbles (kvalues
//          table, low nibbles quants 0..7, high 8..15) each with a UE4M3
//          scale, two q8_0 activation blocks per block.
//
// Block layouts (bytes): tq2_0 = qs[64] (0) | d f16 (64), 66 total; tq1_0 =
// qs[48] (0) | qh[4] (48) | d f16 (52), 54 total; q1_0 = d f16 (0) | qs[16]
// (2), 18 total; q2_0 = d f16 (0) | qs[16] (2), 18 total; nvfp4 = d[4] UE4M3
// (0) | qs[32] (4), 36 total; q8_K 292, q8_0 34.

const (
	tq2_0BlockBytes = 66
	tq1_0BlockBytes = 54
	q1_0BlockBytes  = 18
	q2_0BlockBytes  = 18
	nvfp4BlockBytes = 36
)

// ue4m3ToF32 is ggml_ue4m3_to_fp32: an unsigned 4-bit exponent (bias 7),
// 3-bit mantissa value, halved to match the doubled kvalues table; codes 0
// and 0x7f are zero.
func ue4m3ToF32(x uint8) float32 {
	if x == 0 || x == 0x7f {
		return 0
	}
	exp, man := int(x>>3)&0xf, float64(x&7)
	var raw float64
	if exp == 0 {
		raw = math.Ldexp(man, -9)
	} else {
		raw = math.Ldexp(1+man/8, exp-7)
	}
	return float32(raw * 0.5)
}

// nvfp4Consts: 0: the UE4M3 table (256 x f32); 1024: kvalues_fp4.
func nvfp4Consts() []byte {
	c := make([]byte, 1024+16)
	for i := 0; i < 256; i++ {
		binary.LittleEndian.PutUint32(c[4*i:], math.Float32bits(ue4m3ToF32(uint8(i))))
	}
	for i, v := range kvaluesFP4 {
		c[1024+i] = byte(v)
	}
	return c
}

// ternaryConsts: 0: 16 x 3 (tq1_0 digit extraction); 16: 16 x 86 and 32:
// 16 x 171, the thresholds of ((q*3) >> 8); 48: 16 x 1; 64: kmask
// 1,2,..,128 twice; 80: the TBL index replicating each byte over its four
// 2-bit fields (q2_0); 96: the matching shifts 0,-2,-4,-6; 112: 16 x 3.
func ternaryConsts() []byte {
	c := make([]byte, 128)
	for i := 0; i < 16; i++ {
		c[i] = 3
		c[16+i] = 86
		c[32+i] = 171
		c[48+i] = 1
		c[64+i] = 1 << (i % 8)
		c[80+i] = byte(i / 4)
		c[96+i] = byte(-2 * (i % 4)) // negative: shift right
		c[112+i] = 3
	}
	return c
}

// a64VecDotTQ2_0Kernel: tq2_0 x q8_K. Registers: R1 nb, R2 s, R3 x, R4 y;
// v0 f32 accumulator, v20 i32 block sum, v16 = 3, v17 = 1.
func a64VecDotTQ2_0Kernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	e := newA64Q(&sb)
	w := e.w
	w("// %s: tq2_0 x q8_K dot, 2-bit planes shifted out and SDOTed.", sym)
	e.movi4s0(0)
	e.vecDotPrologue(wide, 8, tq2_0BlockBytes, q8_KBlockBytes, "tq2oob", "tq2reduce")
	e.movi16(16, 3)
	e.movi16(17, 1)
	w("tq2blk:")
	e.movi4s0(20)
	for j := 0; j < 2; j++ {
		e.ldurQ(2, 3, 32*j)
		e.ldurQ(3, 3, 32*j+16)
		for l := 0; l < 4; l++ {
			if l == 0 {
				e.and16(4, 2, 16)
				e.and16(5, 3, 16)
			} else {
				e.ushr16(4, 2, 2*l)
				e.ushr16(5, 3, 2*l)
				e.and16(4, 4, 16)
				e.and16(5, 5, 16)
			}
			e.sub16(4, 4, 17)
			e.sub16(5, 5, 17)
			yo := 4 + 128*j + 32*l
			e.ldurQ(6, 4, yo)
			e.ldurQ(7, 4, yo+16)
			e.sdot(20, 4, 6)
			e.sdot(20, 5, 7)
		}
	}
	e.addv4s(20, 20)
	e.scvtf4s(20, 20)
	e.ldurH(22, 3, 64)
	e.ldurS(23, 4, 0)
	e.fcvtSH(22, 22)
	e.fmulS(22, 22, 23)
	e.fmlaLane(0, 20, 22, 0)
	w("\tADD\t$%d, R3, R3", tq2_0BlockBytes)
	w("\tADD\t$%d, R4, R4", q8_KBlockBytes)
	w("\tSUBW\t$1, R1, R1")
	w("\tCBNZW\tR1, tq2blk")
	w("tq2reduce:")
	e.reduceStore(0, 2)
	w("\tRET")
	w("tq2oob:")
	w("\tB\tovr_oob")
	return sb.String()
}

// a64VecDotTQ1_0Kernel: tq1_0 x q8_K. Digit l of a byte q is
// ((q * 3^l * 3) >> 8) - 1 = ~(cmhs(q*3^l, 86) + cmhs(q*3^l, 171)) as
// signed bytes (the two thresholds of the top two bits of q*3). Registers
// as tq2_0; v16 = 86, v17 = 171, v18 = 3 (the digit multiplier), v21 = 3
// scratch.
func a64VecDotTQ1_0Kernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	e := newA64Q(&sb)
	w := e.w
	cSym := pool.addBlob(ternaryConsts())
	w("// %s: tq1_0 x q8_K dot, base-3 digits by byte multiply and two threshold compares, SDOT.", sym)
	e.movi4s0(0)
	e.vecDotPrologue(wide, 8, tq1_0BlockBytes, q8_KBlockBytes, "tq1oob", "tq1reduce")
	w("\tMOVD\t$·%s(SB), R12", cSym)
	e.ldurQ(18, 12, 0)
	e.ldurQ(16, 12, 16)
	e.ldurQ(17, 12, 32)
	// digit extracts the current digit of the bytes in q into d (signed
	// -1..1) and advances q to the next digit (q *= 3).
	digit := func(d, q int) {
		e.cmhs16(d, q, 16)  // q >= 86
		e.cmhs16(21, q, 17) // q >= 171
		e.add16(d, d, 21)   // 0, -1, -2
		e.mvn16(d, d)       // -1, 0, 1
		e.mul16(q, q, 18)   // next digit
	}
	w("tq1blk:")
	e.movi4s0(20)
	// 32 bytes -> 160 quants: digit l of byte m is quant l*32 + m
	e.ldurQ(2, 3, 0)
	e.ldurQ(3, 3, 16)
	for l := 0; l < 5; l++ {
		digit(4, 2)
		digit(5, 3)
		e.ldurQ(6, 4, 4+32*l)
		e.ldurQ(7, 4, 4+32*l+16)
		e.sdot(20, 4, 6)
		e.sdot(20, 5, 7)
	}
	// 16 bytes -> 80 quants: digit l of byte m is quant 160 + l*16 + m
	e.ldurQ(2, 3, 32)
	for l := 0; l < 5; l++ {
		digit(4, 2)
		e.ldurQ(6, 4, 4+160+16*l)
		e.sdot(20, 4, 6)
	}
	// 4 bytes qh -> 16 quants: digit l of byte m is quant 240 + l*4 + m
	e.ldurS(2, 3, 48)
	w("\tADD\t$244, R4, R5") // ldur reaches only 256 bytes
	for l := 0; l < 4; l++ {
		digit(4, 2)
		e.ldurS(6, 5, 4*l)
		e.sdot(20, 4, 6) // the S loads zero lanes 4..15 of v6, so the digits there add nothing
	}
	e.addv4s(20, 20)
	e.scvtf4s(20, 20)
	e.ldurH(22, 3, 52)
	e.ldurS(23, 4, 0)
	e.fcvtSH(22, 22)
	e.fmulS(22, 22, 23)
	e.fmlaLane(0, 20, 22, 0)
	w("\tADD\t$%d, R3, R3", tq1_0BlockBytes)
	w("\tADD\t$%d, R4, R4", q8_KBlockBytes)
	w("\tSUBW\t$1, R1, R1")
	w("\tCBNZW\tR1, tq1blk")
	w("tq1reduce:")
	e.reduceStore(0, 2)
	w("\tRET")
	w("tq1oob:")
	w("\tB\tovr_oob")
	return sb.String()
}

// a64VecDotQ1_0Kernel: q1_0 x q8_0. Each of the four 32-quant activation
// blocks has its own scale, so the four SDOT sums convert to f32
// separately and accumulate as d0 * (d1 * sum). Registers: R1 nb (q1_0
// blocks), R2 s, R3 x, R4 y; v16 kmask, v18/v19 the byte-spread indices,
// v17 = 1.
func a64VecDotQ1_0Kernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	e := newA64Q(&sb)
	w := e.w
	cSym := pool.addBlob(ternaryConsts())
	w("// %s: q1_0 x q8_0 dot, sign bits expanded to +-1 bytes, SDOT per activation block.", sym)
	e.movi4s0(0)
	e.vecDotPrologue(wide, 7, q1_0BlockBytes, 4*q8_0BlockBytes, "q1oob", "q1reduce")
	w("\tMOVD\t$·%s(SB), R12", cSym)
	e.ldurQ(16, 12, 64)
	e.movi16(17, 1)
	// spread indices: [0 x8 | 1 x8] and [2 x8 | 3 x8] pick the four sign bytes
	w("\tMOVD\t$0, R5")
	e.insDX(18, 0, 5)
	w("\tMOVD\t$0x0101010101010101, R5")
	e.insDX(18, 1, 5)
	w("\tMOVD\t$0x0202020202020202, R5")
	e.insDX(19, 0, 5)
	w("\tMOVD\t$0x0303030303030303, R5")
	e.insDX(19, 1, 5)
	w("q1blk:")
	e.ldurH(22, 3, 0)
	e.fcvtSH(22, 22) // d0
	for k := 0; k < 4; k++ {
		w("\tMOVWU\t%d(R3), R5", 2+4*k) // 32 sign bits
		e.insSW(24, 0, 5)
		e.tbl16(4, 24, 18) // [b0 x8 | b1 x8]
		e.tbl16(5, 24, 19) // [b2 x8 | b3 x8]
		e.cmtst16(4, 4, 16)
		e.cmtst16(5, 5, 16) // 0xff where the bit is set
		e.orr16(4, 4, 17)
		e.orr16(5, 5, 17) // -1 where set, +1 where clear: the negated sign
		e.movi4s0(12)
		yo := 34*k + 2
		e.ldurQ(6, 4, yo)
		e.ldurQ(7, 4, yo+16)
		e.sdot(12, 4, 6)
		e.sdot(12, 5, 7) // -(sum): set bits contributed -y
		e.addv4s(12, 12)
		e.scvtf4s(12, 12)
		e.ldurH(23, 4, 34*k)
		e.fcvtSH(23, 23) // d1
		e.fmulS(23, 23, 22)
		e.fmlsLane(0, 12, 23, 0) // acc -= (d0*d1) * (-sum)
	}
	w("\tADD\t$%d, R3, R3", q1_0BlockBytes)
	w("\tADD\t$%d, R4, R4", 4*q8_0BlockBytes)
	w("\tSUBW\t$1, R1, R1")
	w("\tCBNZW\tR1, q1blk")
	w("q1reduce:")
	e.reduceStore(0, 2)
	w("\tRET")
	w("q1oob:")
	w("\tB\tovr_oob")
	return sb.String()
}

// a64VecDotQ2_0Kernel: q2_0 x q8_0, two activation blocks per q2_0 block.
// Each byte is replicated over four lanes (TBL), shifted right by 0, 2, 4,
// 6 (USHL with negative shifts), masked to 2 bits and offset by -1.
// Registers as q1_0; v16 = 3, v17 = 1, v18 the replicate index, v19 the
// shifts.
func a64VecDotQ2_0Kernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	e := newA64Q(&sb)
	w := e.w
	cSym := pool.addBlob(ternaryConsts())
	w("// %s: q2_0 x q8_0 dot, 2-bit fields spread with TBL/USHL, SDOT per activation block.", sym)
	e.movi4s0(0)
	e.vecDotPrologue(wide, 6, q2_0BlockBytes, 2*q8_0BlockBytes, "q2oob", "q2reduce")
	w("\tMOVD\t$·%s(SB), R12", cSym)
	e.ldurQ(18, 12, 80)
	e.ldurQ(19, 12, 96)
	e.ldurQ(16, 12, 112)
	e.movi16(17, 1)
	w("q2blk:")
	e.ldurH(22, 3, 0)
	e.fcvtSH(22, 22) // d0
	for k := 0; k < 2; k++ {
		e.ldurD(2, 3, 2+8*k) // 8 bytes = 32 quants
		e.dup2d(2, 2, 0)
		// lanes 0..15: bytes 0..3 replicated x4; lanes 16..31 (second vector): bytes 4..7
		e.tbl16(4, 2, 18) // bytes 0..3, each x4
		e.movi16(21, 4)
		e.add16(21, 18, 21)
		e.tbl16(5, 2, 21) // bytes 4..7, each x4
		e.ushl16(4, 4, 19)
		e.ushl16(5, 5, 19)
		e.and16(4, 4, 16)
		e.and16(5, 5, 16)
		e.sub16(4, 4, 17)
		e.sub16(5, 5, 17)
		e.movi4s0(12)
		yo := 34*k + 2
		e.ldurQ(6, 4, yo)
		e.ldurQ(7, 4, yo+16)
		e.sdot(12, 4, 6)
		e.sdot(12, 5, 7)
		e.addv4s(12, 12)
		e.scvtf4s(12, 12)
		e.ldurH(23, 4, 34*k)
		e.fcvtSH(23, 23) // d1
		e.fmulS(23, 23, 22)
		e.fmlaLane(0, 12, 23, 0)
	}
	w("\tADD\t$%d, R3, R3", q2_0BlockBytes)
	w("\tADD\t$%d, R4, R4", 2*q8_0BlockBytes)
	w("\tSUBW\t$1, R1, R1")
	w("\tCBNZW\tR1, q2blk")
	w("q2reduce:")
	e.reduceStore(0, 2)
	w("\tRET")
	w("q2oob:")
	w("\tB\tovr_oob")
	return sb.String()
}

// a64VecDotNVFP4Kernel: nvfp4 x q8_0. Four 16-quant sub-blocks per block,
// each with a UE4M3 scale (through the f32 table) times the scale of the
// q8_0 block it falls in; the fp4 nibbles go through the kvalues table.
// Registers: R1 nb, R2 s, R3 x, R4 y, R12 the UE4M3 table, R13 kvalues;
// v16 = 0x0f, v18 kvalues.
func a64VecDotNVFP4Kernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	e := newA64Q(&sb)
	w := e.w
	cSym := pool.addBlob(nvfp4Consts())
	w("// %s: nvfp4 x q8_0 dot, fp4 nibbles through TBL, UE4M3 sub-block scales through a table.", sym)
	e.movi4s0(0)
	e.vecDotPrologue(wide, 6, nvfp4BlockBytes, 2*q8_0BlockBytes, "nvoob", "nvreduce")
	w("\tMOVD\t$·%s(SB), R12", cSym)
	w("\tADD\t$1024, R12, R13")
	e.ldurQ(18, 13, 0)
	e.movi16(16, 15)
	w("nvblk:")
	for sIdx := 0; sIdx < 4; sIdx++ {
		q8 := sIdx / 2
		off := (sIdx % 2) * 16
		e.ldurD(2, 3, 4+8*sIdx) // 8 nibble bytes = 16 quants
		e.and16(4, 2, 16)
		e.ushr16(5, 2, 4)
		e.tbl16(4, 18, 4) // quants 0..7 in lanes 0..7
		e.tbl16(5, 18, 5) // quants 8..15 in lanes 0..7
		e.ldurD(6, 4, 34*q8+2+off)
		e.ldurD(7, 4, 34*q8+2+off+8)
		e.movi4s0(12)
		e.sdot(12, 4, 6)
		e.sdot(12, 5, 7) // the D loads zero lanes 8..15, and kvalues[0] = 0 keeps the TBL there at 0
		e.addv4s(12, 12)
		e.scvtf4s(12, 12)
		w("\tMOVBU\t%d(R3), R5", sIdx)
		w("\tMOVWU\t(R12)(R5<<2), R5")
		e.fmovSW(22, 5) // ue4m3(d[s])
		e.ldurH(23, 4, 34*q8)
		e.fcvtSH(23, 23) // dy
		e.fmulS(22, 22, 23)
		e.fmlaLane(0, 12, 22, 0)
	}
	w("\tADD\t$%d, R3, R3", nvfp4BlockBytes)
	w("\tADD\t$%d, R4, R4", 2*q8_0BlockBytes)
	w("\tSUBW\t$1, R1, R1")
	w("\tCBNZW\tR1, nvblk")
	w("nvreduce:")
	e.reduceStore(0, 2)
	w("\tRET")
	w("nvoob:")
	w("\tB\tovr_oob")
	return sb.String()
}
