package asm

import (
	"fmt"
	"strings"
)

// The single-query flash-attention KV loop (ggml_flash_attn_kv_f16,
// exported by llama-wasm as dbg_flash_attn_kv_f16): for one query
// against KV positions [ic_start, ic_end) it computes the F16 K.Q dot,
// the online-softmax update and the F16 V accumulate into the f32 VKQ
// row. The transpiled loop pays two override calls, a libm expf and a
// register-starved body per position; this body keeps the whole step
// in registers with the exp polynomial of the soft_max kernel
// (ggml_v_expf's arithmetic). FastMath only: fused multiply-adds, the
// polynomial expf, f32 partial sums in vector lanes.
//
// C signature (llama-wasm patches/wasm-flash-attn-kv-loop-export.patch):
//
//	void f(const struct ggml_flash_attn_kv_f16_args *a)
//
// with the wasm64 layout of the struct (96 bytes): Q_q 0, k_base 8,
// nbk1 16, v_base 24, nbv1 32, mp 40, SM 48, VKQ32 56, ic_start 64,
// ic_end 72, slope 80 (f32), scale 84 (f32), DK 88 (i32), DV 92 (i32).
// One pointer argument keeps the export inside the register-assigned
// signatures wasm2go lowers to asm (a 14-argument signature falls back
// to Go and loses its override).
//
// DK and DV must be multiples of 8 (every head size llama.cpp ships);
// the C dispatcher only calls the export for F16 K/V without a logit
// softcap. mp may be null. SM[0] = S, SM[1] = M are read and written.

// flashAttnArgs is the ABI0 frame: the module pointer, then the args
// pointer. Only the memory64 layout of the struct is described.
func flashAttnArgs(wide bool) (map[string]int, int) {
	if wide {
		return map[string]int{"l0": 8}, 16
	}
	return map[string]int{"l0": 8}, 12
}

// flash-attn args struct offsets (wasm64).
const (
	faArgQ     = 0
	faArgK     = 8
	faArgNbk   = 16
	faArgV     = 24
	faArgNbv   = 32
	faArgMask  = 40
	faArgSM    = 48
	faArgVKQ   = 56
	faArgStart = 64
	faArgEnd   = 72
	faArgSlope = 80
	faArgScale = 84
	faArgDK    = 88
	faArgDV    = 92
	faArgSize  = 96
)

// faEmitter carries the encoders the flash-attention bodies share.
type faEmitter struct {
	e *a64VecExp
	q *a64Q
	w func(format string, args ...any)
}

func newFAEmitter(sb *strings.Builder) *faEmitter {
	e := &a64VecExp{}
	e.w = func(format string, args ...any) { fmt.Fprintf(sb, format+"\n", args...) }
	e.word = func(enc uint32, dis string) { e.w("\tWORD $0x%08x // %s", enc, dis) }
	return &faEmitter{e: e, q: newA64Q(sb), w: e.w}
}

func (f *faEmitter) ldrQPost(rt, rn int) { // ldr q<rt>, [x<rn>], #16
	f.e.word(0x3CC10400|uint32(rn)<<5|uint32(rt), fmt.Sprintf("ldr q%d, [x%d], #16", rt, rn))
}
func (f *faEmitter) ldrQ(rt, rn, off int) { // ldr q<rt>, [x<rn>, #off] (off multiple of 16)
	f.e.word(0x3DC00000|uint32(off/16)<<10|uint32(rn)<<5|uint32(rt), fmt.Sprintf("ldr q%d, [x%d, #%d]", rt, rn, off))
}
func (f *faEmitter) strQ(rt, rn, off int) {
	f.e.word(0x3D800000|uint32(off/16)<<10|uint32(rn)<<5|uint32(rt), fmt.Sprintf("str q%d, [x%d, #%d]", rt, rn, off))
}
func (f *faEmitter) fcmpS(n, m int) {
	f.e.word(0x1E202000|uint32(m)<<16|uint32(n)<<5, fmt.Sprintf("fcmp s%d, s%d", n, m))
}
func (f *faEmitter) fsubS(d, n, m int) {
	f.e.word(0x1E203800|lane3(d, n, m), fmt.Sprintf("fsub s%d, s%d, s%d", d, n, m))
}
func (f *faEmitter) fmulS(d, n, m int) {
	f.e.word(0x1E200800|lane3(d, n, m), fmt.Sprintf("fmul s%d, s%d, s%d", d, n, m))
}
func (f *faEmitter) fmaddS(d, n, m, a int) {
	f.e.word(0x1F000000|uint32(m)<<16|uint32(a)<<10|uint32(n)<<5|uint32(d), fmt.Sprintf("fmadd s%d, s%d, s%d, s%d", d, n, m, a))
}
func (f *faEmitter) fmovSzr(d int) { f.e.word(0x1E2703E0|uint32(d), fmt.Sprintf("fmov s%d, wzr", d)) }
func (f *faEmitter) fmovS1(d int)  { f.e.word(0x1E2E1000|uint32(d), fmt.Sprintf("fmov s%d, #1.0", d)) }
func (f *faEmitter) dupS0(d, n int) {
	f.e.word(0x4E040400|uint32(n)<<5|uint32(d), fmt.Sprintf("dup v%d.4s, v%d.s[0]", d, n))
}
func (f *faEmitter) fcvtl(d, n int) {
	f.e.word(0x0E217800|uint32(n)<<5|uint32(d), fmt.Sprintf("fcvtl v%d.4s, v%d.4h", d, n))
}
func (f *faEmitter) fcvtl2(d, n int) {
	f.e.word(0x4E217800|uint32(n)<<5|uint32(d), fmt.Sprintf("fcvtl2 v%d.4s, v%d.8h", d, n))
}
func (f *faEmitter) ldrHPost(rt, rn int) {
	f.e.word(0x7C402400|uint32(rn)<<5|uint32(rt), fmt.Sprintf("ldr h%d, [x%d], #2", rt, rn))
}
func (f *faEmitter) fcvtSH(d, n int) {
	f.e.word(0x1EE24000|uint32(n)<<5|uint32(d), fmt.Sprintf("fcvt s%d, h%d", d, n))
}
func (f *faEmitter) fmulLane(d, n, m, idx int) {
	f.e.word(0x4F809000|idxLH(idx)|lane3(d, n, m), fmt.Sprintf("fmul v%d.4s, v%d.4s, v%d.s[%d]", d, n, m, idx))
}
func (f *faEmitter) strS(t, n, off int) {
	f.e.word(0xBD000000|uint32(off/4)<<10|uint32(n)<<5|uint32(t), fmt.Sprintf("str s%d, [x%d, #%d]", t, n, off))
}
func (f *faEmitter) ldrS(t, n, off int) {
	f.e.word(0xBD400000|uint32(off/4)<<10|uint32(n)<<5|uint32(t), fmt.Sprintf("ldr s%d, [x%d, #%d]", t, n, off))
}

// a64FlashAttnKernel emits the NEON body under sym: the shared prologue,
// the per-position loop, the state store.
func a64FlashAttnKernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	f := newFAEmitter(&sb)
	cSym := pool.addBlob(vecExpConsts())
	f.prologue(sym, wide)
	f.e.loadConsts(cSym, 13)
	f.perPositionLoop()
	f.epilogue()
	return sb.String()
}

// prologue loads the args struct into the register set every body uses
// (R1 DK, R2 DV, R3 Q, R4 K row, R5 nbk1, R6 V row, R7 nbv1, R8 mask,
// R9 positions, R10 SM, R11 VKQ; v12 S, v13 M, v14 scale, v15 slope,
// v16 -inf), checks bounds and branches to fadone on an empty range.
// The exp constants are the caller's to load. R22/R23 flag an 8-wide
// tail of DK/DV, R1/R2 count 16-wide chunks.
func (f *faEmitter) prologue(sym string, wide bool) {
	e, w := f.e, f.w
	args, _ := flashAttnArgs(wide)
	movPtr := "MOVWU"
	if wide {
		movPtr = "MOVD"
	}
	w("// %s: single-query flash-attention KV loop (F16 K/V, f32 VKQ), exp in registers.", sym)
	// --- the args struct (R0 = host pointer after the range check).
	w("\t%s\tl0+%d(FP), R0", movPtr, args["l0"])
	w("\tADD\t$%d, R0, R27", faArgSize)
	w("\tCMP\tR27, R21")
	w("\tBLO\tfaoob")
	w("\tADD\tR20, R0, R0")
	w("\tMOVW\t%d(R0), R1", faArgDK)
	w("\tMOVW\t%d(R0), R2", faArgDV)
	w("\tMOVD\t%d(R0), R3", faArgQ)
	w("\tMOVD\t%d(R0), R4", faArgK)
	w("\tMOVD\t%d(R0), R5", faArgNbk)
	w("\tMOVD\t%d(R0), R6", faArgV)
	w("\tMOVD\t%d(R0), R7", faArgNbv)
	w("\tMOVD\t%d(R0), R8", faArgMask)
	w("\tMOVD\t%d(R0), R12", faArgStart) // ic_start
	w("\tMOVD\t%d(R0), R9", faArgEnd)    // ic_end
	w("\tMOVD\t%d(R0), R10", faArgSM)
	w("\tMOVD\t%d(R0), R11", faArgVKQ)
	w("\tFMOVS\t%d(R0), F15", faArgSlope)
	w("\tFMOVS\t%d(R0), F14", faArgScale)
	// SM + 8, VKQ + 4*DV, Q + 2*DK
	w("\tADD\t$8, R10, R27")
	w("\tCMP\tR27, R21")
	w("\tBLO\tfaoob")
	w("\tADD\tR2<<2, R11, R27")
	w("\tCMP\tR27, R21")
	w("\tBLO\tfaoob")
	w("\tADD\tR1<<1, R3, R27")
	w("\tCMP\tR27, R21")
	w("\tBLO\tfaoob")
	w("\tADD\tR20, R10, R10")
	w("\tADD\tR20, R11, R11")
	w("\tADD\tR20, R3, R3")
	f.ldrS(12, 10, 0) // S
	f.ldrS(13, 10, 4) // M
	// positions: R9 = ic_end - ic_start; nothing to do when <= 0 (the
	// state is stored back unchanged).
	w("\tSUB\tR12, R9, R9")
	w("\tCMP\t$0, R9")
	w("\tBLE\tfadone")
	// K/V rows: base + ic_start*nb .. base + (ic_end-1)*nb + 2*D must fit.
	// Go's MADD is Rm, Ra, Rn, Rd: Rd = Ra + Rn*Rm.
	w("\tMADD\tR5, R4, R12, R4") // R4 = k_base + ic_start*nbk1
	w("\tMADD\tR7, R6, R12, R6")
	w("\tSUB\t$1, R9, R13")
	w("\tMUL\tR13, R5, R27")
	w("\tADD\tR4, R27, R27")
	w("\tADD\tR1<<1, R27, R27")
	w("\tCMP\tR27, R21")
	w("\tBLO\tfaoob")
	w("\tMUL\tR13, R7, R27")
	w("\tADD\tR6, R27, R27")
	w("\tADD\tR2<<1, R27, R27")
	w("\tCMP\tR27, R21")
	w("\tBLO\tfaoob")
	w("\tADD\tR20, R4, R4")
	w("\tADD\tR20, R6, R6")
	w("\tCBZ\tR8, famaskok")
	w("\tADD\tR12<<1, R8, R8") // mp + ic_start (elements)
	w("\tADD\tR9<<1, R8, R27")
	w("\tCMP\tR27, R21")
	w("\tBLO\tfaoob")
	w("\tADD\tR20, R8, R8")
	w("famaskok:")
	// -inf: 0xff800000
	w("\tMOVW\t$0xff800000, R27")
	e.word(0x1E270000|uint32(27)<<5|uint32(16), "fmov s16, w27")
	// DK, DV are multiples of 8: R1/R2 count 16-wide chunks, R22/R23
	// flag a trailing 8-wide half chunk.
	w("\tLSRW\t$3, R1, R22")
	w("\tANDW\t$1, R22, R22")
	w("\tLSRW\t$3, R2, R23")
	w("\tANDW\t$1, R23, R23")
	w("\tLSRW\t$4, R1, R1") // DK / 16 chunks
	w("\tLSRW\t$4, R2, R2") // DV / 16 chunks
}

// perPositionLoop is the original algorithm: one position at a time,
// f16 widened to f32, VKQ in memory (exp constants at v20..v31).
func (f *faEmitter) perPositionLoop() {
	e, q, w := f.e, f.q, f.w
	w("fapos:")
	// --- mask value mv (v17): slope * f16(mp[ic]); -inf skips the position.
	f.fmovSzr(17)
	w("\tCBZ\tR8, fadot")
	f.ldrHPost(17, 8)
	f.fcvtSH(17, 17)
	f.fmulS(17, 17, 15)
	f.fcmpS(17, 16)
	w("\tBEQ\tfaskip")
	w("fadot:")
	// --- s = K.Q (f16 x f16 -> f32), R13 = K row, R14 = Q, R12 = chunks.
	w("\tMOVD\tR4, R13")
	w("\tMOVD\tR3, R14")
	w("\tMOVW\tR1, R12")
	e.word(0x4F000400|1, "movi v1.4s, #0")
	e.word(0x4F000400|2, "movi v2.4s, #0")
	w("\tCBZW\tR12, fadottail")
	w("fadotloop:")
	f.ldrQPost(3, 13)
	f.ldrQPost(4, 13)
	f.ldrQPost(5, 14)
	f.ldrQPost(6, 14)
	f.fcvtl(7, 3)
	f.fcvtl2(8, 3)
	f.fcvtl(9, 5)
	f.fcvtl2(10, 5)
	e.fmlaV(1, 7, 9)
	e.fmlaV(2, 8, 10)
	f.fcvtl(7, 4)
	f.fcvtl2(8, 4)
	f.fcvtl(9, 6)
	f.fcvtl2(10, 6)
	e.fmlaV(1, 7, 9)
	e.fmlaV(2, 8, 10)
	w("\tSUBW\t$1, R12, R12")
	w("\tCBNZW\tR12, fadotloop")
	w("fadottail:")
	w("\tCBZW\tR22, fadotdone")
	f.ldrQ(3, 13, 0)
	f.ldrQ(5, 14, 0)
	f.fcvtl(7, 3)
	f.fcvtl2(8, 3)
	f.fcvtl(9, 5)
	f.fcvtl2(10, 5)
	e.fmlaV(1, 7, 9)
	e.fmlaV(2, 8, 10)
	w("fadotdone:")
	e.faddV(1, 1, 2)
	q.faddp4s(1, 1, 1)
	q.faddpS(1, 1)
	// s = s*scale + mv
	f.fmaddS(1, 1, 14, 17)
	// --- online softmax: ms (v18), vs (v19).
	f.fcmpS(1, 13)
	w("\tBGT\tfanewmax")
	// vs = exp(s - M); ms = 1
	f.fsubS(0, 1, 13)
	f.dupS0(0, 0)
	e.exp(0, 0)
	w("\tFMOVS\tF0, F19")
	f.fmovS1(18)
	w("\tB\tfamad")
	w("fanewmax:")
	// ms = exp(Mold - s); M = s; VKQ *= ms; vs = 1
	f.fsubS(0, 13, 1)
	w("\tFMOVS\tF1, F13") // M = s (v1 is exp scratch)
	f.dupS0(0, 0)
	e.exp(0, 0)
	w("\tFMOVS\tF0, F18")
	f.fmovS1(19)
	w("\tMOVD\tR11, R14")
	w("\tMOVW\tR2, R12")
	w("\tCBZW\tR12, fascaletail")
	w("fascale:")
	f.ldrQ(3, 14, 0)
	f.ldrQ(4, 14, 16)
	f.ldrQ(5, 14, 32)
	f.ldrQ(6, 14, 48)
	f.fmulLane(3, 3, 18, 0)
	f.fmulLane(4, 4, 18, 0)
	f.fmulLane(5, 5, 18, 0)
	f.fmulLane(6, 6, 18, 0)
	f.strQ(3, 14, 0)
	f.strQ(4, 14, 16)
	f.strQ(5, 14, 32)
	f.strQ(6, 14, 48)
	w("\tADD\t$64, R14, R14")
	w("\tSUBW\t$1, R12, R12")
	w("\tCBNZW\tR12, fascale")
	w("fascaletail:")
	w("\tCBZW\tR23, famad")
	f.ldrQ(3, 14, 0)
	f.ldrQ(4, 14, 16)
	f.fmulLane(3, 3, 18, 0)
	f.fmulLane(4, 4, 18, 0)
	f.strQ(3, 14, 0)
	f.strQ(4, 14, 16)
	w("famad:")
	// --- VKQ += vs * V (f16 -> f32), R13 = V row, R14 = VKQ, R12 = chunks.
	w("\tMOVD\tR6, R13")
	w("\tMOVD\tR11, R14")
	w("\tMOVW\tR2, R12")
	w("\tCBZW\tR12, famadtail")
	w("famadloop:")
	f.ldrQPost(3, 13)
	f.ldrQPost(4, 13)
	f.fcvtl(5, 3)
	f.fcvtl2(6, 3)
	f.fcvtl(7, 4)
	f.fcvtl2(8, 4)
	f.ldrQ(9, 14, 0)
	f.ldrQ(10, 14, 16)
	f.ldrQ(11, 14, 32)
	f.ldrQ(0, 14, 48)
	e.fmlaLane(9, 5, 19, 0)
	e.fmlaLane(10, 6, 19, 0)
	e.fmlaLane(11, 7, 19, 0)
	e.fmlaLane(0, 8, 19, 0)
	f.strQ(9, 14, 0)
	f.strQ(10, 14, 16)
	f.strQ(11, 14, 32)
	f.strQ(0, 14, 48)
	w("\tADD\t$64, R14, R14")
	w("\tSUBW\t$1, R12, R12")
	w("\tCBNZW\tR12, famadloop")
	w("famadtail:")
	w("\tCBZW\tR23, famaddone")
	f.ldrQ(3, 13, 0)
	f.fcvtl(5, 3)
	f.fcvtl2(6, 3)
	f.ldrQ(9, 14, 0)
	f.ldrQ(10, 14, 16)
	e.fmlaLane(9, 5, 19, 0)
	e.fmlaLane(10, 6, 19, 0)
	f.strQ(9, 14, 0)
	f.strQ(10, 14, 16)
	w("famaddone:")
	// S = S*ms + vs
	f.fmaddS(12, 12, 18, 19)
	w("faskip:")
	w("\tADD\tR4, R5, R4")
	w("\tADD\tR6, R7, R6")
	w("\tSUB\t$1, R9, R9")
	w("\tCBNZ\tR9, fapos")
}

// epilogue stores S and M back and traps on out-of-bounds.
func (f *faEmitter) epilogue() {
	w := f.w
	w("fadone:")
	f.strS(12, 10, 0)
	f.strS(13, 10, 4)
	w("\tRET")
	w("faoob:")
	w("\tB\tovr_oob")
}
