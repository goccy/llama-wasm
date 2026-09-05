package asm

import (
	"encoding/binary"
	"strings"
)

// iq3_xxs and iq3_s x q8_K dots (ggml_vec_dot_iq3_xxs_q8_K,
// ggml_vec_dot_iq3_s_q8_K): 3-bit codebook formats. Every 8-quant group is
// one u32 of the grid (four magnitudes, each byte an odd value) looked up by
// an 8-bit (iq3_xxs) or 9-bit (iq3_s) index, with a sign per quant: iq3_xxs
// packs four 7-bit sign codes per sub-block into a u32 whose top nibble is
// the sub-block scale (ls = 2*nibble + 1) and expands each code through the
// ksigns table (the eighth sign bit is the code's parity); iq3_s stores the
// sign bytes and nibble scales directly and the ninth index bit in qh.
// The kernels gather the grid words and sign masks through general
// registers into vector lanes (as llama.cpp's NEON bodies do), multiply the
// magnitudes by +-1 sign bytes, SDOT against the activation sub-block,
// weight the sub-block sum by its integer scale and scale the super-block's
// i32 total once by f16(x.d) * y.d (iq3_xxs additionally by 0.25).
// FastMath only.
//
// Block layouts (bytes): iq3_xxs = d f16 (0) | qs[64] indices (2) | gas u32
// x8 (66), 98 total; iq3_s = d f16 (0) | qs[64] (2) | qh[8] (66) | signs[32]
// (74) | scales[4] (106), 110 total; q8_K = d f32 (0) | qs[256] (4) |
// bsums[16] (260), 292 total.

const (
	iq3_xxsBlockBytes = 98
	iq3_sBlockBytes   = 110
)

// kevenSigns expands each 7-bit sign code into eight +-1 bytes (0x01 / 0xff)
// from ksignsIQ2XS, llama.cpp's keven_signs_q2xs table.
func kevenSigns() []byte {
	c := make([]byte, 128*8)
	for code := 0; code < 128; code++ {
		bits := ksignsIQ2XS[code]
		for j := 0; j < 8; j++ {
			if bits>>j&1 != 0 {
				c[8*code+j] = 0xff
			} else {
				c[8*code+j] = 0x01
			}
		}
	}
	return c
}

// iq3xxsConsts: 0: iq3xxs_grid (256 x u32); 1024: keven signs (128 x u64).
func iq3xxsConsts() []byte {
	c := make([]byte, 2048)
	for i, v := range iq3xxsGrid {
		binary.LittleEndian.PutUint32(c[4*i:], v)
	}
	copy(c[1024:], kevenSigns())
	return c
}

// iq3sConsts: 0: iq3s_grid (512 x u32); 2048: TBL index spreading sign bytes
// 0/1 over lanes 0..7/8..15; 2064: the same for bytes 2/3; 2080: kmask
// 1,2,4,..,128 twice.
func iq3sConsts() []byte {
	c := make([]byte, 2096)
	for i, v := range iq3sGrid {
		binary.LittleEndian.PutUint32(c[4*i:], v)
	}
	for i := 0; i < 16; i++ {
		c[2048+i] = byte(i / 8)
		c[2064+i] = byte(2 + i/8)
		c[2080+i] = 1 << (i % 8)
	}
	return c
}

// a64VecDotIQ3XXSKernel emits the iq3_xxs dot under sym. Registers: R1 nb,
// R2 s, R3 x, R4 y, R12 grid, R13 sign table, R5-R8 scratch; v0 the f32
// accumulator, v17 = 0.25, v20 the super-block's i32 sum, v21 the scale.
func a64VecDotIQ3XXSKernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	e := newA64Q(&sb)
	w := e.w
	cSym := pool.addBlob(iq3xxsConsts())
	w("// %s: iq3_xxs x q8_K dot, grid and sign gathers through general registers, SDOT per sub-block.", sym)
	e.movi4s0(0)
	e.vecDotPrologue(wide, 8, iq3_xxsBlockBytes, q8_KBlockBytes, "i3xoob", "i3xreduce")
	w("\tMOVD\t$·%s(SB), R12", cSym)
	w("\tADD\t$1024, R12, R13")
	w("\tMOVW\t$0x3E800000, R5") // 0.25f
	e.fmovSW(17, 5)
	w("i3xblk:")
	e.movi4s0(20)
	for ib := 0; ib < 8; ib++ {
		w("\tMOVD\t%d(R3), R5", 2+8*ib)   // eight grid indices
		w("\tMOVWU\t%d(R3), R6", 66+4*ib) // sign codes | scale
		for k := 0; k < 8; k++ {
			w("\tUBFX\t$%d, R5, $8, R7", 8*k)
			w("\tMOVWU\t(R12)(R7<<2), R8")
			e.insSW(2+k/4, k%4, 8)
		}
		for l := 0; l < 4; l++ {
			w("\tUBFX\t$%d, R6, $7, R7", 7*l)
			w("\tMOVD\t(R13)(R7<<3), R8")
			e.insDX(4+l/2, l%2, 8)
		}
		e.mul16(2, 2, 4)
		e.mul16(3, 3, 5)
		e.ldurQ(6, 4, 4+32*ib)
		e.ldurQ(7, 4, 4+32*ib+16)
		e.movi4s0(12)
		e.sdot(12, 2, 6)
		e.sdot(12, 3, 7)
		w("\tLSRW\t$28, R6, R7")
		w("\tLSLW\t$1, R7, R7")
		w("\tADDW\t$1, R7, R7") // ls = 2*(aux >> 28) + 1
		e.dup4sW(21, 7)
		e.mla4s(20, 12, 21)
	}
	e.addv4s(20, 20)
	e.scvtf4s(20, 20)
	e.ldurH(22, 3, 0)
	e.ldurS(23, 4, 0)
	e.fcvtSH(22, 22)
	e.fmulS(22, 22, 23)
	e.fmulS(22, 22, 17) // the format's 0.25
	e.fmlaLane(0, 20, 22, 0)
	w("\tADD\t$%d, R3, R3", iq3_xxsBlockBytes)
	w("\tADD\t$%d, R4, R4", q8_KBlockBytes)
	w("\tSUBW\t$1, R1, R1")
	w("\tCBNZW\tR1, i3xblk")
	w("i3xreduce:")
	e.reduceStore(0, 2)
	w("\tRET")
	w("i3xoob:")
	w("\tB\tovr_oob")
	return sb.String()
}

// a64VecDotIQ3SKernel emits the iq3_s dot under sym. Registers as above
// plus R9 the sub-block's four sign bytes; v18 kmask, v19/v22 the sign-byte
// spread indices, v23 = 0x01.
func a64VecDotIQ3SKernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	e := newA64Q(&sb)
	w := e.w
	cSym := pool.addBlob(iq3sConsts())
	w("// %s: iq3_s x q8_K dot, 9-bit grid gathers, sign bytes expanded with TBL/CMTST, SDOT per sub-block.", sym)
	e.movi4s0(0)
	e.vecDotPrologue(wide, 8, iq3_sBlockBytes, q8_KBlockBytes, "i3soob", "i3sreduce")
	w("\tMOVD\t$·%s(SB), R12", cSym)
	w("\tADD\t$2048, R12, R13") // ldur reaches only 256 bytes: the tables past the grid go through R13
	e.ldurQ(19, 13, 0)
	e.ldurQ(22, 13, 16)
	e.ldurQ(18, 13, 32)
	e.movi16(23, 1)
	w("i3sblk:")
	e.movi4s0(20)
	for ib := 0; ib < 8; ib++ {
		w("\tMOVD\t%d(R3), R5", 2+8*ib)   // eight low index bytes
		w("\tMOVBU\t%d(R3), R6", 66+ib)   // their ninth bits
		w("\tMOVWU\t%d(R3), R9", 74+4*ib) // four sign bytes
		for k := 0; k < 8; k++ {
			w("\tUBFX\t$%d, R5, $8, R7", 8*k)
			w("\tUBFX\t$%d, R6, $1, R8", k)
			w("\tORR\tR8<<8, R7, R7")
			w("\tMOVWU\t(R12)(R7<<2), R8")
			e.insSW(2+k/4, k%4, 8)
		}
		e.insSW(24, 0, 9)   // the four sign bytes in lanes 0..3
		e.tbl16(4, 24, 19)  // [s0 x8 | s1 x8]
		e.tbl16(5, 24, 22)  // [s2 x8 | s3 x8]
		e.cmtst16(4, 4, 18) // 0xff where the quant's sign bit is set
		e.cmtst16(5, 5, 18)
		e.orr16(4, 4, 23) // -1 / +1
		e.orr16(5, 5, 23)
		e.mul16(2, 2, 4)
		e.mul16(3, 3, 5)
		e.ldurQ(6, 4, 4+32*ib)
		e.ldurQ(7, 4, 4+32*ib+16)
		e.movi4s0(12)
		e.sdot(12, 2, 6)
		e.sdot(12, 3, 7)
		w("\tMOVBU\t%d(R3), R7", 106+ib/2)
		if ib%2 == 0 {
			w("\tANDW\t$0xf, R7, R7")
		} else {
			w("\tLSRW\t$4, R7, R7")
		}
		w("\tLSLW\t$1, R7, R7")
		w("\tADDW\t$1, R7, R7") // ls = 2*nibble + 1
		e.dup4sW(21, 7)
		e.mla4s(20, 12, 21)
	}
	e.addv4s(20, 20)
	e.scvtf4s(20, 20)
	e.ldurH(25, 3, 0)
	e.ldurS(26, 4, 0)
	e.fcvtSH(25, 25)
	e.fmulS(25, 25, 26)
	e.fmlaLane(0, 20, 25, 0)
	w("\tADD\t$%d, R3, R3", iq3_sBlockBytes)
	w("\tADD\t$%d, R4, R4", q8_KBlockBytes)
	w("\tSUBW\t$1, R1, R1")
	w("\tCBNZW\tR1, i3sblk")
	w("i3sreduce:")
	e.reduceStore(0, 2)
	w("\tRET")
	w("i3soob:")
	w("\tB\tovr_oob")
	return sb.String()
}
