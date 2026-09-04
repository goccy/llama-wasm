package asm

import (
	"fmt"
	"strings"
)

// The FEAT_FHM body of the single-query flash-attention KV loop
// (dbg_flash_attn_kv_f16; see flashattn_a64.go for the contract). Same
// state and arguments as the NEON body, but positions go in blocks of
// eight, the way ggml's native NEON path keeps its f16 arithmetic:
//
//   - K.Q is FMLAL/FMLAL2 of the f16 rows straight into f32 lanes (no
//     widening), one 16-byte load of K and of Q per eight elements.
//   - The block's eight scores take one vectorized exp (two 4-lane
//     calls) instead of one per position; masked (-inf) positions and
//     the lanes past the block end contribute exp(-200) = 0.
//   - The softmax weights are rounded to f16 once and V is accumulated
//     in f16 registers with FMLA by element (the native path's VKQ16),
//     64 elements resident at a time; the f32 VKQ32 state converts to
//     and from that f16 accumulator around the call.
//
// Head sizes: DK any multiple of 8, DV 64 or 128; anything else runs
// the per-position loop of the NEON body. FastMath only.
//
// Registers (fast path): R0 args, R17 DK/8, R2 DV/16, R3 Q, R4 K row,
// R5 nbk1, R6 V row, R7 nbv1, R8 mask element, R9 positions left, R10
// SM, R11 VKQ32, R12 block size, R13..R16 loop scratch, R19 scratch
// base; v0..v11 scratch (the exp routine's), v12..v23 exp constants,
// v24..v31 the resident VKQ16 half. S and M live in SM between blocks.
const (
	faFHMVKQ16   = 0   // f16 accumulator, up to 128 elements
	faFHMScores  = 256 // 8 f32 scores
	faFHMScratch = 288
	faFHMFrame   = 304
	faFHMBlock   = 8
	faFHMExpBase = 12
)

// a64FlashAttnFHMKernel emits the kernel under sym.
func a64FlashAttnFHMKernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	f := newFAEmitter(&sb)
	e, q, w := f.e, f.q, f.w
	cSym := pool.addBlob(vecExpConsts())
	word := e.word
	fmlal := func(d, n, m int) {
		word(0x4E20EC00|lane3(d, n, m), fmt.Sprintf("fmlal v%d.4s, v%d.4h, v%d.4h", d, n, m))
	}
	fmlal2 := func(d, n, m int) {
		word(0x6E20CC00|lane3(d, n, m), fmt.Sprintf("fmlal2 v%d.4s, v%d.4h, v%d.4h", d, n, m))
	}
	idxH := func(idx int) uint32 { return uint32(idx&1)<<20 | uint32(idx>>1&1)<<21 | uint32(idx>>2&1)<<11 }
	fmla8hLane := func(d, n, m, idx int) {
		word(0x4F001000|idxH(idx)|lane3(d, n, m), fmt.Sprintf("fmla v%d.8h, v%d.8h, v%d.h[%d]", d, n, m, idx))
	}
	fmul8hLane := func(d, n, m, idx int) {
		word(0x4F009000|idxH(idx)|lane3(d, n, m), fmt.Sprintf("fmul v%d.8h, v%d.8h, v%d.h[%d]", d, n, m, idx))
	}
	fcvtn := func(d, n int) { word(0x0E216800|uint32(n)<<5|uint32(d), fmt.Sprintf("fcvtn v%d.4h, v%d.4s", d, n)) }
	fcvtn2 := func(d, n int) { word(0x4E216800|uint32(n)<<5|uint32(d), fmt.Sprintf("fcvtn2 v%d.8h, v%d.4s", d, n)) }
	fcvtHS := func(d, n int) { word(0x1E23C000|uint32(n)<<5|uint32(d), fmt.Sprintf("fcvt h%d, s%d", d, n)) }
	fmaxvS := func(d, n int) { word(0x6E30F800|uint32(n)<<5|uint32(d), fmt.Sprintf("fmaxv s%d, v%d.4s", d, n)) }
	fmaxS := func(d, n, m int) { word(0x1E204800|lane3(d, n, m), fmt.Sprintf("fmax s%d, s%d, s%d", d, n, m)) }
	fmax4s := func(d, n, m int) {
		word(0x4E20F400|lane3(d, n, m), fmt.Sprintf("fmax v%d.4s, v%d.4s, v%d.4s", d, n, m))
	}
	faddS := func(d, n, m int) { word(0x1E202800|lane3(d, n, m), fmt.Sprintf("fadd s%d, s%d, s%d", d, n, m)) }
	fmovSW := func(d, n int) { word(0x1E270000|uint32(n)<<5|uint32(d), fmt.Sprintf("fmov s%d, w%d", d, n)) }
	movi4s0 := func(d int) { word(0x4F000400|uint32(d), fmt.Sprintf("movi v%d.4s, #0", d)) }
	movV := func(d, n int) {
		word(0x4EA01C00|uint32(n)<<16|uint32(n)<<5|uint32(d), fmt.Sprintf("mov v%d.16b, v%d.16b", d, n))
	}
	ldrQ := f.ldrQ
	strQ := f.strQ

	e.cbase = faFHMExpBase
	f.prologue(sym, wide)
	// fast path only for DV 64 or 128: R2 = DV/16 (4 or 8) with no tail
	w("\tCBNZW\tR23, fhmslow")
	w("\tCMPW\t$4, R2")
	w("\tBEQ\tfhmfast")
	w("\tCMPW\t$8, R2")
	w("\tBEQ\tfhmfast")
	w("fhmslow:")
	e.cbase = 0
	e.loadConsts(cSym, 13)
	f.perPositionLoop()
	w("\tB\tfadone")

	w("fhmfast:")
	e.cbase = faFHMExpBase
	e.loadConsts(cSym, 13)
	w("\tMOVD\t$fhmscratch-%d(SP), R19", faFHMScratch)
	// R17 = DK/8, R16 = DV/8, R23 = DV/64 halves
	w("\tLSLW\t$1, R1, R17")
	w("\tADDW\tR22, R17, R17")
	w("\tLSLW\t$1, R2, R16")
	w("\tLSRW\t$2, R2, R23") // DV/64 halves (R23, the tail flag, is 0 here)
	// VKQ32 -> VKQ16 scratch
	w("\tMOVD\tR11, R13")
	w("\tMOVD\tR19, R14")
	w("\tMOVW\tR16, R15")
	w("fhmcvtin:")
	ldrQ(0, 13, 0)
	ldrQ(1, 13, 16)
	fcvtn(0, 0)
	fcvtn2(0, 1)
	strQ(0, 14, 0)
	w("\tADD\t$32, R13, R13")
	w("\tADD\t$16, R14, R14")
	w("\tSUBW\t$1, R15, R15")
	w("\tCBNZW\tR15, fhmcvtin")

	w("fhmblk:")
	// R12 = min(8, positions left)
	w("\tMOVD\t$%d, R12", faFHMBlock)
	w("\tCMP\tR12, R9")
	w("\tBGE\tfhmnblk")
	w("\tMOVD\tR9, R12")
	w("fhmnblk:")
	// scores v2 (0..3), v3 (4..7) start at -inf
	w("\tMOVW\t$0xff800000, R27")
	fmovSW(2, 27)
	f.dupS0(2, 2)
	movV(3, 2)
	w("\tMOVD\tR4, R13") // K row i
	for i := 0; i < faFHMBlock; i++ {
		if i > 0 {
			w("\tCMPW\t$%d, R12", i)
			w("\tBLE\tfhmscored")
		}
		// dot = K_i . Q via FMLAL/FMLAL2 into v0/v1
		w("\tMOVD\tR13, R15")
		w("\tMOVD\tR3, R14")
		w("\tMOVW\tR17, R26")
		movi4s0(0)
		movi4s0(1)
		w("fhmdot%d:", i)
		f.ldrQPost(4, 15)
		f.ldrQPost(5, 14)
		fmlal(0, 4, 5)
		fmlal2(1, 4, 5)
		w("\tSUBW\t$1, R26, R26")
		w("\tCBNZW\tR26, fhmdot%d", i)
		e.faddV(0, 0, 1)
		q.faddp4s(0, 0, 0)
		q.faddpS(0, 0)
		// mv = slope * f16(mp[i]) (0 without a mask); s = dot*scale + mv
		f.fmovSzr(6)
		w("\tCBZ\tR8, fhmnomask%d", i)
		word(0x7D400000|uint32(i)<<10|uint32(8)<<5|6, fmt.Sprintf("ldr h6, [x8, #%d]", 2*i))
		f.fcvtSH(6, 6)
		w("\tFMOVS\t%d(R0), F7", faArgSlope)
		f.fmulS(6, 6, 7)
		w("fhmnomask%d:", i)
		w("\tFMOVS\t%d(R0), F7", faArgScale)
		f.fmaddS(0, 0, 7, 6)
		q.insS(2+i/4, i%4, 0, 0)
		w("\tADD\tR13, R5, R13")
	}
	w("fhmscored:")
	// block max (s30; the exp routine clobbers v0..v11, so the block max
	// and M live above it); all -inf (every position masked) skips the
	// block
	fmaxvS(4, 2)
	fmaxvS(5, 3)
	fmaxS(30, 4, 5)
	w("\tMOVW\t$0xff800000, R27")
	fmovSW(6, 27)
	f.fcmpS(30, 6)
	w("\tBEQ\tfhmadvance")
	// M_old (s31); a new max rescales the f16 accumulator and S
	f.ldrS(31, 10, 4)
	f.fcmpS(30, 31)
	w("\tBLE\tfhmnorescale")
	f.strS(30, 10, 4)
	f.fcmpS(31, 6)
	w("\tBEQ\tfhmnewm") // M_old = -inf: nothing accumulated yet
	// (the exp clobbers v1..v11: park the scores in scratch meanwhile)
	strQ(2, 19, faFHMScores)
	strQ(3, 19, faFHMScores+16)
	f.fsubS(0, 31, 30)
	f.dupS0(0, 0)
	e.exp(0, 0) // ms
	ldrQ(2, 19, faFHMScores)
	ldrQ(3, 19, faFHMScores+16)
	f.ldrS(1, 10, 0)
	f.fmulS(1, 1, 0)
	f.strS(1, 10, 0)
	fcvtHS(0, 0)
	w("\tMOVD\tR19, R14")
	w("\tMOVW\tR16, R15")
	w("fhmrescale:")
	ldrQ(1, 14, 0)
	fmul8hLane(1, 1, 0, 0)
	strQ(1, 14, 0)
	w("\tADD\t$16, R14, R14")
	w("\tSUBW\t$1, R15, R15")
	w("\tCBNZW\tR15, fhmrescale")
	w("fhmnewm:")
	w("\tFMOVS\tF30, F31")
	w("fhmnorescale:")
	// p = exp(max(s - M, -200)): masked lanes and the lanes past the
	// block end flush to zero. The exp routine clobbers v1..v11, so the
	// second score vector waits in scratch.
	f.dupS0(6, 31)
	e.fsubV(2, 2, 6)
	e.fsubV(3, 3, 6)
	w("\tMOVW\t$0xc3480000, R27") // -200.0f
	fmovSW(7, 27)
	f.dupS0(7, 7)
	fmax4s(2, 2, 7)
	fmax4s(3, 3, 7)
	// (its input must be v0: v1..v11 are its scratch)
	strQ(3, 19, faFHMScores+16)
	movV(0, 2)
	e.exp(0, 0)
	strQ(0, 19, faFHMScores)
	ldrQ(0, 19, faFHMScores+16)
	e.exp(0, 0)
	movV(3, 0)
	ldrQ(2, 19, faFHMScores)
	// S += sum(p)
	e.faddV(0, 2, 3)
	q.faddp4s(0, 0, 0)
	q.faddpS(0, 0)
	f.ldrS(1, 10, 0)
	faddS(1, 1, 0)
	f.strS(1, 10, 0)
	// p as eight halves in v10
	fcvtn(10, 2)
	fcvtn2(10, 3)
	// VKQ16 += p_i * V_i, one resident 64-element half at a time
	w("\tMOVD\tR19, R14") // half's accumulator in scratch
	w("\tMOVD\tR6, R24")  // half's V base
	w("\tMOVW\tR23, R25")
	w("fhmhalf:")
	for c := 0; c < 8; c++ {
		ldrQ(24+c, 14, 16*c)
	}
	w("\tMOVD\tR24, R13")
	for i := 0; i < faFHMBlock; i++ {
		if i > 0 {
			w("\tCMPW\t$%d, R12", i)
			w("\tBLE\tfhmhalfdone")
		}
		for c := 0; c < 8; c++ {
			ldrQ(c%2, 13, 16*c)
			fmla8hLane(24+c, c%2, 10, i)
		}
		w("\tADD\tR13, R7, R13")
	}
	w("fhmhalfdone:")
	for c := 0; c < 8; c++ {
		strQ(24+c, 14, 16*c)
	}
	w("\tADD\t$128, R14, R14")
	w("\tADD\t$128, R24, R24")
	w("\tSUBW\t$1, R25, R25")
	w("\tCBNZW\tR25, fhmhalf")
	w("fhmadvance:")
	w("\tMADD\tR5, R4, R12, R4")
	w("\tMADD\tR7, R6, R12, R6")
	w("\tCBZ\tR8, fhmnomaskadv")
	w("\tADD\tR12<<1, R8, R8")
	w("fhmnomaskadv:")
	w("\tSUB\tR12, R9, R9")
	w("\tCBNZ\tR9, fhmblk")
	// VKQ16 -> VKQ32
	w("\tMOVD\tR11, R13")
	w("\tMOVD\tR19, R14")
	w("\tMOVW\tR16, R15")
	w("fhmcvtout:")
	ldrQ(0, 14, 0)
	f.fcvtl(1, 0)
	f.fcvtl2(2, 0)
	strQ(1, 13, 0)
	strQ(2, 13, 16)
	w("\tADD\t$32, R13, R13")
	w("\tADD\t$16, R14, R14")
	w("\tSUBW\t$1, R15, R15")
	w("\tCBNZW\tR15, fhmcvtout")
	// the epilogue stores v12/v13: reload the state kept in memory
	f.ldrS(12, 10, 0)
	f.ldrS(13, 10, 4)
	f.epilogue()
	return sb.String()
}
