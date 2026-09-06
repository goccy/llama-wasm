package asm

import "strings"

// iq4_nl x q8_0 dot (ggml_vec_dot_iq4_nl_q8_0): per 32-quant block the
// nibbles index kvalues_iq4nl (TBL, signed bytes) and two SDOTs against
// the activation block give the integer dot, scaled by f16(x.d) *
// f16(y.d). Two blocks per step into two accumulators. FastMath only.
//
// Block layouts (bytes): iq4_nl = d f16 (0) | qs[16] (2), 18 total;
// q8_0 = d f16 (0) | qs[32] (2), 34 total.

const (
	iq4_nlBlockBytes = 18
	mxfp4BlockBytes  = 17 // e u8 (0) | qs[16] (1)
)

// kvaluesFP4 is ggml's kvalues_fp4 / kvalues_mxfp4: the sixteen E2M1
// values as signed bytes (doubled; the E8M0 block scale is halved to
// match).
var kvaluesFP4 = [16]int8{0, 1, 2, 3, 4, 6, 8, 12, 0, -1, -2, -3, -4, -6, -8, -12}

// lut32Layout describes a 32-quant nibble format whose nibbles index a
// signed 16-entry table: iq4_nl (f16 scale) and mxfp4 (E8M0 scale).
type lut32Layout struct {
	name       string
	lbl        string
	blockBytes int
	qsOff      int
	table      [16]int8
	e8m0       bool // block scale is an E8M0 byte at offset 0 (else f16)
}

var (
	lut32IQ4NL = lut32Layout{name: "iq4_nl", lbl: "iq4", blockBytes: iq4_nlBlockBytes, qsOff: 2, table: kvaluesIQ4NL}
	lut32MXFP4 = lut32Layout{name: "mxfp4", lbl: "mx4", blockBytes: mxfp4BlockBytes, qsOff: 1, table: kvaluesFP4, e8m0: true}
)

// iq4nlConsts: 0: kvalues_iq4nl (16 signed bytes).
func iq4nlConsts() []byte { return lut32Consts(lut32IQ4NL) }

func lut32Consts(L lut32Layout) []byte {
	c := make([]byte, 16)
	for i := range L.table {
		c[i] = byte(L.table[i])
	}
	return c
}

// a64VecDotIQ4NLKernel emits the kernel under sym. Registers: R1 nb,
// R2 s, R3 x, R4 y; v0/v1 the two f32 accumulators; v16 = 0x0f, v18 the
// kvalues table.
func a64VecDotIQ4NLKernel(sym string, pool *ConstPool, wide bool) string {
	return a64VecDotLUT32(sym, pool, wide, lut32IQ4NL)
}

// a64VecDotMXFP4Kernel emits the mxfp4 x q8_0 dot: the iq4_nl body with
// the fp4 table and ggml_e8m0_to_fp32_half of the block's E8M0 byte as
// its scale (2^(e-128): bits (e-1) << 23, or the denormal 0x00200000 << e
// for e < 2), built in R5-R7.
func a64VecDotMXFP4Kernel(sym string, pool *ConstPool, wide bool) string {
	return a64VecDotLUT32(sym, pool, wide, lut32MXFP4)
}

func a64VecDotLUT32(sym string, pool *ConstPool, wide bool, L lut32Layout) string {
	var sb strings.Builder
	e := newA64Q(&sb)
	w := e.w
	cSym := pool.addBlob(lut32Consts(L))

	// block emits one iq4_nl x q8_0 block at x+xo / y+yo into acc using
	// the temporaries t (7 vector registers).
	block := func(xo, yo, acc int, t [7]int) {
		qs, lo, hi, ylo, yhi, dot, sc := t[0], t[1], t[2], t[3], t[4], t[5], t[6]
		e.ldurQ(qs, 3, xo+L.qsOff)
		e.ldurQ(ylo, 4, yo+2)
		e.ldurQ(yhi, 4, yo+18)
		e.and16(lo, qs, 16)
		e.ushr16(hi, qs, 4)
		e.tbl16(lo, 18, lo) // kvalues[nibble]
		e.tbl16(hi, 18, hi)
		e.movi4s0(dot)
		e.sdot(dot, lo, ylo)
		e.sdot(dot, hi, yhi)
		if L.e8m0 {
			w("\tMOVBU\t%d(R3), R5", xo)
			w("\tSUBW\t$1, R5, R6")
			w("\tLSLW\t$23, R6, R6")
			w("\tMOVW\t$0x00200000, R7")
			w("\tLSLW\tR5, R7, R7") // 0x00200000 << e, the e < 2 denormals
			w("\tCMPW\t$2, R5")
			w("\tCSELW\tLO, R7, R6, R6")
			e.fmovSW(sc, 6)
		} else {
			e.ldurH(sc, 3, xo)
			e.fcvtSH(sc, sc)
		}
		e.ldurH(qs, 4, yo) // qs is free now
		e.fcvtSH(qs, qs)
		e.fmulS(sc, sc, qs)
		e.scvtf4s(dot, dot)
		e.fmlaLane(acc, dot, sc, 0)
	}
	tA := [7]int{2, 4, 6, 8, 10, 12, 14}
	tB := [7]int{3, 5, 7, 9, 11, 13, 15}

	w("// %s: %s x q8_0 dot, TBL table lookup and SDOT, two blocks per step.", sym, L.name)
	e.movi4s0(0)
	e.movi4s0(1)
	e.vecDotPrologue(wide, 5, L.blockBytes, q8_0BlockBytes, L.lbl+"oob", L.lbl+"reduce")
	w("\tMOVD\t$·%s(SB), R5", cSym)
	e.ldurQ(18, 5, 0)
	e.movi16(16, 15)
	w("%sloop2:", L.lbl)
	w("\tCMPW\t$2, R1")
	w("\tBLT\t%stail", L.lbl)
	block(0, 0, 0, tA)
	block(L.blockBytes, q8_0BlockBytes, 1, tB)
	w("\tADD\t$%d, R3, R3", 2*L.blockBytes)
	w("\tADD\t$%d, R4, R4", 2*q8_0BlockBytes)
	w("\tSUBW\t$2, R1, R1")
	w("\tB\t%sloop2", L.lbl)
	w("%stail:", L.lbl)
	w("\tCBZW\tR1, %sreduce", L.lbl)
	block(0, 0, 0, tA)
	w("%sreduce:", L.lbl)
	e.fadd4s(0, 0, 1)
	e.reduceStore(0, 2)
	w("\tRET")
	w("%soob:", L.lbl)
	w("\tB\tovr_oob")
	return sb.String()
}
