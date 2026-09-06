package asm

import (
	"encoding/binary"
	"strings"
)

// iq2_xxs, iq2_xs and iq2_s x q8_K dots (ggml_vec_dot_iq2_*_q8_K): 2-bit
// codebook formats where every 8-quant group is one u64 of the grid (eight
// magnitudes) looked up by an 8- (iq2_xxs), 9- (iq2_xs) or 10-bit (iq2_s)
// index with a sign per quant, and every 32-quant sub-block has one
// (iq2_xxs) or two (iq2_xs, iq2_s: one per 16 quants) integer scales
// 2*nibble + 1. iq2_xxs packs four indices and a u32 of four 7-bit sign
// codes plus the scale nibble per sub-block; iq2_xs packs index and sign
// code into one u16 per group; iq2_s stores sign bytes and the two high
// index bits in qh. The sign codes expand through the keven table
// (+-1 bytes), the stored sign bytes through TBL/CMTST. Same gather-and-
// SDOT structure as the iq3 kernels; the super-block's i32 total is scaled
// once by f16(x.d) * y.d * 0.125. FastMath only.
//
// Block layouts (bytes): iq2_xxs = d f16 (0) | qs u16[32] (2), 66 total;
// iq2_xs = d (0) | qs u16[32] (2) | scales[8] (66), 74 total; iq2_s = d (0)
// | qs[32] indices (2) | signs[32] (34) | qh[8] (66) | scales[8] (74), 82
// total.

const (
	iq2_xxsBlockBytes = 66
	iq2_xsBlockBytes  = 74
	iq2_sBlockBytes   = 82
)

// iq2Layout selects one of the three formats.
type iq2Layout struct {
	name, lbl  string
	blockBytes int
	gridBytes  int // size of the codebook (u64 entries)
	twoScales  bool
}

var (
	iq2xxsL = iq2Layout{name: "iq2_xxs", lbl: "i2x", blockBytes: iq2_xxsBlockBytes, gridBytes: 2048}
	iq2xsL  = iq2Layout{name: "iq2_xs", lbl: "i2s", blockBytes: iq2_xsBlockBytes, gridBytes: 4096, twoScales: true}
	iq2sL   = iq2Layout{name: "iq2_s", lbl: "i2t", blockBytes: iq2_sBlockBytes, gridBytes: 8192, twoScales: true}
)

// iq2Consts: 0: the grid (u64 entries); then for iq2_xxs / iq2_xs the
// keven sign table (128 x u64), for iq2_s the TBL spread indices (bytes
// 0/1, bytes 2/3) and kmask.
func iq2Consts(L iq2Layout) []byte {
	var grid []uint64
	switch L.name {
	case "iq2_xxs":
		grid = iq2xxsGrid[:]
	case "iq2_xs":
		grid = iq2xsGrid[:]
	default:
		grid = iq2sGrid[:]
	}
	tail := kevenSigns()
	if L.name == "iq2_s" {
		tail = make([]byte, 48)
		for i := 0; i < 16; i++ {
			tail[i] = byte(i / 8)
			tail[16+i] = byte(2 + i/8)
			tail[32+i] = 1 << (i % 8)
		}
	}
	c := make([]byte, L.gridBytes+len(tail))
	for i, v := range grid {
		binary.LittleEndian.PutUint64(c[8*i:], v)
	}
	copy(c[L.gridBytes:], tail)
	return c
}

func a64VecDotIQ2XXSKernel(sym string, pool *ConstPool, wide bool) string {
	return a64VecDotIQ2(sym, pool, wide, iq2xxsL)
}
func a64VecDotIQ2XSKernel(sym string, pool *ConstPool, wide bool) string {
	return a64VecDotIQ2(sym, pool, wide, iq2xsL)
}
func a64VecDotIQ2SKernel(sym string, pool *ConstPool, wide bool) string {
	return a64VecDotIQ2(sym, pool, wide, iq2sL)
}

// a64VecDotIQ2 emits the dot for L under sym. Registers: R1 nb, R2 s, R3
// x, R4 y, R12 grid, R13 sign table / spread constants, R5-R9 scratch;
// v0 the f32 accumulator, v17 = 0.125, v20 the super-block's i32 sum,
// v21 the scale; for iq2_s v18 kmask, v19/v22 the spread indices, v23 =
// 0x01.
func a64VecDotIQ2(sym string, pool *ConstPool, wide bool, L iq2Layout) string {
	var sb strings.Builder
	e := newA64Q(&sb)
	w := e.w
	cSym := pool.addBlob(iq2Consts(L))
	w("// %s: %s x q8_K dot, u64 grid gathers through general registers, SDOT per 16 quants.", sym, L.name)
	e.movi4s0(0)
	e.vecDotPrologue(wide, 8, L.blockBytes, q8_KBlockBytes, L.lbl+"oob", L.lbl+"reduce")
	w("\tMOVD\t$·%s(SB), R12", cSym)
	w("\tADD\t$%d, R12, R13", L.gridBytes)
	w("\tMOVW\t$0x3E000000, R5") // 0.125f
	e.fmovSW(17, 5)
	if L.name == "iq2_s" {
		e.ldurQ(19, 13, 0)
		e.ldurQ(22, 13, 16)
		e.ldurQ(18, 13, 32)
		e.movi16(23, 1)
	}
	w("%sblk:", L.lbl)
	e.movi4s0(20)
	for ib := 0; ib < 8; ib++ {
		switch L.name {
		case "iq2_xxs":
			w("\tMOVD\t%d(R3), R5", 2+8*ib) // four indices | sign codes | scale
			for l := 0; l < 4; l++ {
				w("\tUBFX\t$%d, R5, $8, R7", 8*l)
				w("\tMOVD\t(R12)(R7<<3), R8")
				e.insDX(2+l/2, l%2, 8)
				w("\tUBFX\t$%d, R5, $7, R7", 32+7*l)
				w("\tMOVD\t(R13)(R7<<3), R8")
				e.insDX(4+l/2, l%2, 8)
			}
		case "iq2_xs":
			w("\tMOVD\t%d(R3), R5", 2+8*ib) // four u16: index | code << 9
			for l := 0; l < 4; l++ {
				w("\tUBFX\t$%d, R5, $9, R7", 16*l)
				w("\tMOVD\t(R12)(R7<<3), R8")
				e.insDX(2+l/2, l%2, 8)
				w("\tUBFX\t$%d, R5, $7, R7", 16*l+9)
				w("\tMOVD\t(R13)(R7<<3), R8")
				e.insDX(4+l/2, l%2, 8)
			}
		default: // iq2_s
			w("\tMOVWU\t%d(R3), R5", 2+4*ib)  // four low index bytes
			w("\tMOVBU\t%d(R3), R6", 66+ib)   // their two high bits each
			w("\tMOVWU\t%d(R3), R9", 34+4*ib) // four sign bytes
			for l := 0; l < 4; l++ {
				w("\tUBFX\t$%d, R5, $8, R7", 8*l)
				w("\tUBFX\t$%d, R6, $2, R8", 2*l)
				w("\tORR\tR8<<8, R7, R7")
				w("\tMOVD\t(R12)(R7<<3), R8")
				e.insDX(2+l/2, l%2, 8)
			}
			e.insSW(24, 0, 9)
			e.tbl16(4, 24, 19)
			e.tbl16(5, 24, 22)
			e.cmtst16(4, 4, 18)
			e.cmtst16(5, 5, 18)
			e.orr16(4, 4, 23)
			e.orr16(5, 5, 23)
		}
		e.mul16(2, 2, 4)
		e.mul16(3, 3, 5)
		e.ldurQ(6, 4, 4+32*ib)
		e.ldurQ(7, 4, 4+32*ib+16)
		if L.twoScales {
			e.movi4s0(12)
			e.sdot(12, 2, 6)
			e.movi4s0(13)
			e.sdot(13, 3, 7)
			scOff := 66 + ib
			if L.name == "iq2_s" {
				scOff = 74 + ib
			}
			w("\tMOVBU\t%d(R3), R7", scOff)
			w("\tANDW\t$0xf, R7, R8")
			w("\tLSLW\t$1, R8, R8")
			w("\tADDW\t$1, R8, R8") // ls1
			e.dup4sW(21, 8)
			e.mla4s(20, 12, 21)
			w("\tLSRW\t$4, R7, R8")
			w("\tLSLW\t$1, R8, R8")
			w("\tADDW\t$1, R8, R8") // ls2
			e.dup4sW(21, 8)
			e.mla4s(20, 13, 21)
		} else {
			e.movi4s0(12)
			e.sdot(12, 2, 6)
			e.sdot(12, 3, 7)
			w("\tLSR\t$60, R5, R7")
			w("\tLSLW\t$1, R7, R7")
			w("\tADDW\t$1, R7, R7") // ls = 2*(aux >> 28) + 1
			e.dup4sW(21, 7)
			e.mla4s(20, 12, 21)
		}
	}
	e.addv4s(20, 20)
	e.scvtf4s(20, 20)
	e.ldurH(25, 3, 0)
	e.ldurS(26, 4, 0)
	e.fcvtSH(25, 25)
	e.fmulS(25, 25, 26)
	e.fmulS(25, 25, 17) // the format's 0.125
	e.fmlaLane(0, 20, 25, 0)
	w("\tADD\t$%d, R3, R3", L.blockBytes)
	w("\tADD\t$%d, R4, R4", q8_KBlockBytes)
	w("\tSUBW\t$1, R1, R1")
	w("\tCBNZW\tR1, %sblk", L.lbl)
	w("%sreduce:", L.lbl)
	e.reduceStore(0, 2)
	w("\tRET")
	w("%soob:", L.lbl)
	w("\tB\tovr_oob")
	return sb.String()
}
