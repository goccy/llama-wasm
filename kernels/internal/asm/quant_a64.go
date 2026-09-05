package asm

import (
	"fmt"
	"strings"
)

// a64Q holds the NEON emitters the quantized vec_dot kernels share
// (q5_0, q4_K, q6_K against q8 activations). Every instruction is
// written as a WORD with its disassembly beside it; the encodings were
// cross-checked against clang's integrated assembler.
type a64Q struct {
	w    func(format string, args ...any)
	word func(enc uint32, dis string)
}

func newA64Q(sb *strings.Builder) *a64Q {
	e := &a64Q{}
	e.w = func(format string, args ...any) { fmt.Fprintf(sb, format+"\n", args...) }
	e.word = func(enc uint32, dis string) { e.w("\tWORD $0x%08x // %s", enc, dis) }
	return e
}

func lane3(d, n, m int) uint32 { return uint32(m)<<16 | uint32(n)<<5 | uint32(d) }
func idxLH(idx int) uint32     { return uint32(idx&1)<<21 | uint32(idx>>1)<<11 }

// --- loads and stores (unscaled immediate, -256..255).

func (e *a64Q) ldurQ(rt, rn, imm int) {
	e.word(0x3CC00000|uint32(imm&0x1FF)<<12|uint32(rn)<<5|uint32(rt), fmt.Sprintf("ldur q%d, [x%d, #%d]", rt, rn, imm))
}

func (e *a64Q) ldurD(rt, rn, imm int) {
	e.word(0xFC400000|uint32(imm&0x1FF)<<12|uint32(rn)<<5|uint32(rt), fmt.Sprintf("ldur d%d, [x%d, #%d]", rt, rn, imm))
}

func (e *a64Q) ldurS(rt, rn, imm int) {
	e.word(0xBC400000|uint32(imm&0x1FF)<<12|uint32(rn)<<5|uint32(rt), fmt.Sprintf("ldur s%d, [x%d, #%d]", rt, rn, imm))
}

func (e *a64Q) ldurH(rt, rn, imm int) {
	e.word(0x7C400000|uint32(imm&0x1FF)<<12|uint32(rn)<<5|uint32(rt), fmt.Sprintf("ldur h%d, [x%d, #%d]", rt, rn, imm))
}

// --- byte-lane logic and arithmetic (.16b).

func (e *a64Q) and16(d, n, m int) {
	e.word(0x4E201C00|lane3(d, n, m), fmt.Sprintf("and v%d.16b, v%d.16b, v%d.16b", d, n, m))
}

func (e *a64Q) eor16(d, n, m int) {
	e.word(0x6E201C00|lane3(d, n, m), fmt.Sprintf("eor v%d.16b, v%d.16b, v%d.16b", d, n, m))
}

func (e *a64Q) orr16(d, n, m int) {
	e.word(0x4EA01C00|lane3(d, n, m), fmt.Sprintf("orr v%d.16b, v%d.16b, v%d.16b", d, n, m))
}

// bic16: d = n & ~m.
func (e *a64Q) bic16(d, n, m int) {
	e.word(0x4E601C00|lane3(d, n, m), fmt.Sprintf("bic v%d.16b, v%d.16b, v%d.16b", d, n, m))
}

// cmtst16: d = (n & m) != 0 ? 0xff : 0 per byte.
func (e *a64Q) cmtst16(d, n, m int) {
	e.word(0x4E208C00|lane3(d, n, m), fmt.Sprintf("cmtst v%d.16b, v%d.16b, v%d.16b", d, n, m))
}

func (e *a64Q) sub16(d, n, m int) {
	e.word(0x6E208400|lane3(d, n, m), fmt.Sprintf("sub v%d.16b, v%d.16b, v%d.16b", d, n, m))
}

func (e *a64Q) ushr16(d, n, imm int) {
	e.word(0x6F000400|uint32((16-imm)&0xF)<<16|uint32(n)<<5|uint32(d), fmt.Sprintf("ushr v%d.16b, v%d.16b, #%d", d, n, imm))
}

func (e *a64Q) shl16(d, n, imm int) {
	e.word(0x4F005400|uint32(8|imm)<<16|uint32(n)<<5|uint32(d), fmt.Sprintf("shl v%d.16b, v%d.16b, #%d", d, n, imm))
}

// tbl16: d[i] = n[m[i]] (one-register table).
func (e *a64Q) tbl16(d, n, m int) {
	e.word(0x4E000000|lane3(d, n, m), fmt.Sprintf("tbl v%d.16b, {v%d.16b}, v%d.16b", d, n, m))
}

func (e *a64Q) movi16(d, imm int) {
	e.word(0x4F00E400|uint32(imm>>5)<<16|uint32(imm&0x1F)<<5|uint32(d), fmt.Sprintf("movi v%d.16b, #%d", d, imm))
}

func (e *a64Q) movi4s0(d int) {
	e.word(0x4F000400|uint32(d), fmt.Sprintf("movi v%d.4s, #0", d))
}

// --- integer dot / widening.

// sdot: d.4s += dot4(n.16b, m.16b), signed x signed.
func (e *a64Q) sdot(d, n, m int) {
	e.word(0x4E809400|lane3(d, n, m), fmt.Sprintf("sdot v%d.4s, v%d.16b, v%d.16b", d, n, m))
}

func (e *a64Q) add4s(d, n, m int) {
	e.word(0x4EA08400|lane3(d, n, m), fmt.Sprintf("add v%d.4s, v%d.4s, v%d.4s", d, n, m))
}

func (e *a64Q) mul4s(d, n, m int) {
	e.word(0x4EA09C00|lane3(d, n, m), fmt.Sprintf("mul v%d.4s, v%d.4s, v%d.4s", d, n, m))
}

// mlaLane: d.4s += n.4s * m.s[idx].
func (e *a64Q) mlaLane(d, n, m, idx int) {
	e.word(0x6F800000|idxLH(idx)|lane3(d, n, m), fmt.Sprintf("mla v%d.4s, v%d.4s, v%d.s[%d]", d, n, m, idx))
}

func (e *a64Q) sshll8h(d, n int) {
	e.word(0x0F08A400|uint32(n)<<5|uint32(d), fmt.Sprintf("sshll v%d.8h, v%d.8b, #0", d, n))
}

func (e *a64Q) sshll2_8h(d, n int) {
	e.word(0x4F08A400|uint32(n)<<5|uint32(d), fmt.Sprintf("sshll2 v%d.8h, v%d.16b, #0", d, n))
}

func (e *a64Q) sshll4s(d, n int) {
	e.word(0x0F10A400|uint32(n)<<5|uint32(d), fmt.Sprintf("sshll v%d.4s, v%d.4h, #0", d, n))
}

func (e *a64Q) sshll2_4s(d, n int) {
	e.word(0x4F10A400|uint32(n)<<5|uint32(d), fmt.Sprintf("sshll2 v%d.4s, v%d.8h, #0", d, n))
}

func (e *a64Q) ushll8h(d, n int) {
	e.word(0x2F08A400|uint32(n)<<5|uint32(d), fmt.Sprintf("ushll v%d.8h, v%d.8b, #0", d, n))
}

func (e *a64Q) faddS(d, n, m int) {
	e.word(0x1E202800|lane3(d, n, m), fmt.Sprintf("fadd s%d, s%d, s%d", d, n, m))
}

func (e *a64Q) ushll2_8h(d, n int) {
	e.word(0x6F08A400|uint32(n)<<5|uint32(d), fmt.Sprintf("ushll2 v%d.8h, v%d.16b, #0", d, n))
}

func (e *a64Q) ushll4s(d, n int) {
	e.word(0x2F10A400|uint32(n)<<5|uint32(d), fmt.Sprintf("ushll v%d.4s, v%d.4h, #0", d, n))
}

func (e *a64Q) ushll2_4s(d, n int) {
	e.word(0x6F10A400|uint32(n)<<5|uint32(d), fmt.Sprintf("ushll2 v%d.4s, v%d.8h, #0", d, n))
}

// smull / smull2: d.4s = n.4h * m.4h (low / high halves); smlal
// accumulate.
func (e *a64Q) smull4s(d, n, m int) {
	e.word(0x0E60C000|lane3(d, n, m), fmt.Sprintf("smull v%d.4s, v%d.4h, v%d.4h", d, n, m))
}

func (e *a64Q) smull2_4s(d, n, m int) {
	e.word(0x4E60C000|lane3(d, n, m), fmt.Sprintf("smull2 v%d.4s, v%d.8h, v%d.8h", d, n, m))
}

func (e *a64Q) smlal4s(d, n, m int) {
	e.word(0x0E608000|lane3(d, n, m), fmt.Sprintf("smlal v%d.4s, v%d.4h, v%d.4h", d, n, m))
}

func (e *a64Q) smlal2_4s(d, n, m int) {
	e.word(0x4E608000|lane3(d, n, m), fmt.Sprintf("smlal2 v%d.4s, v%d.8h, v%d.8h", d, n, m))
}

func (e *a64Q) addp8h(d, n, m int) {
	e.word(0x4E60BC00|lane3(d, n, m), fmt.Sprintf("addp v%d.8h, v%d.8h, v%d.8h", d, n, m))
}

func (e *a64Q) addv4s(d, n int) {
	e.word(0x4EB1B800|uint32(n)<<5|uint32(d), fmt.Sprintf("addv s%d, v%d.4s", d, n))
}

// --- scalar / element moves.

func (e *a64Q) dup16W(d, n int) {
	e.word(0x4E010C00|uint32(n)<<5|uint32(d), fmt.Sprintf("dup v%d.16b, w%d", d, n))
}

func (e *a64Q) fmovDX(d, n int) {
	e.word(0x9E670000|uint32(n)<<5|uint32(d), fmt.Sprintf("fmov d%d, x%d", d, n))
}

func (e *a64Q) fmovSW(d, n int) {
	e.word(0x1E270000|uint32(n)<<5|uint32(d), fmt.Sprintf("fmov s%d, w%d", d, n))
}

func (e *a64Q) movVsW(d, idx, n int) {
	e.word(0x4E001C00|uint32(idx<<3|4)<<16|uint32(n)<<5|uint32(d), fmt.Sprintf("mov v%d.s[%d], w%d", d, idx, n))
}

// --- float.

func (e *a64Q) fcvtSH(d, n int) {
	e.word(0x1EE24000|uint32(n)<<5|uint32(d), fmt.Sprintf("fcvt s%d, h%d", d, n))
}

func (e *a64Q) fcvtl(d, n int) {
	e.word(0x0E217800|uint32(n)<<5|uint32(d), fmt.Sprintf("fcvtl v%d.4s, v%d.4h", d, n))
}

func (e *a64Q) fmulS(d, n, m int) {
	e.word(0x1E200800|lane3(d, n, m), fmt.Sprintf("fmul s%d, s%d, s%d", d, n, m))
}

func (e *a64Q) scvtf4s(d, n int) {
	e.word(0x4E21D800|uint32(n)<<5|uint32(d), fmt.Sprintf("scvtf v%d.4s, v%d.4s", d, n))
}

// fmlaLane: d.4s += n.4s * m.s[idx]; fmlsLane subtracts.
func (e *a64Q) fmlaLane(d, n, m, idx int) {
	e.word(0x4F801000|idxLH(idx)|lane3(d, n, m), fmt.Sprintf("fmla v%d.4s, v%d.4s, v%d.s[%d]", d, n, m, idx))
}

func (e *a64Q) fmlsLane(d, n, m, idx int) {
	e.word(0x4F805000|idxLH(idx)|lane3(d, n, m), fmt.Sprintf("fmls v%d.4s, v%d.4s, v%d.s[%d]", d, n, m, idx))
}

func (e *a64Q) fadd4s(d, n, m int) {
	e.word(0x4E20D400|lane3(d, n, m), fmt.Sprintf("fadd v%d.4s, v%d.4s, v%d.4s", d, n, m))
}

func (e *a64Q) faddp4s(d, n, m int) {
	e.word(0x6E20D400|lane3(d, n, m), fmt.Sprintf("faddp v%d.4s, v%d.4s, v%d.4s", d, n, m))
}

func (e *a64Q) faddpS(d, n int) {
	e.word(0x7E30D800|uint32(n)<<5|uint32(d), fmt.Sprintf("faddp s%d, v%d.2s", d, n))
}

// reduceStore sums the four lanes of acc into s(acc) and stores it at
// (R<sReg>): the kernels' common epilogue.
func (e *a64Q) reduceStore(acc, sReg int) {
	e.faddp4s(acc, acc, acc)
	e.faddpS(acc, acc)
	e.w("\tFMOVS\tF%d, (R%d)", acc, sReg)
}

// vecDotArgs is the frame of ggml's vec_dot signature
//
//	(int n, float *s, size_t bs, const void *vx, size_t bx, const void *vy, size_t by, int nrc)
//
// shared by every quantized dot; bs/bx/by are unused and nrc is 1 by
// contract.
func vecDotArgs(wide bool) (map[string]int, int) { return vecDotF16Args(wide) }

// vecDotPrologue loads n/32-style block counts and the three pointers
// with their range checks: R1 = nb (n >> shift), R2 = s (host), R3 = x
// (host), R4 = y (host). A zero nb skips the pointer checks (the
// address may be anything when nothing is read) and jumps to zeroLabel
// with the accumulators still zero.
func (e *a64Q) vecDotPrologue(wide bool, shift, xBlock, yBlock int, oob, zeroLabel string) {
	args, _ := vecDotArgs(wide)
	movPtr := "MOVWU"
	if wide {
		movPtr = "MOVD"
	}
	w := e.w
	w("\tMOVW\tl0+%d(FP), R1", args["l0"])
	w("\tLSRW\t$%d, R1, R1", shift)
	w("\t%s\tl1+%d(FP), R2", movPtr, args["l1"])
	w("\tADD\t$4, R2, R27")
	w("\tCMP\tR27, R21")
	w("\tBLO\t%s", oob)
	w("\tADD\tR20, R2, R2")
	w("\tCBZW\tR1, %s", zeroLabel)
	w("\t%s\tl3+%d(FP), R3", movPtr, args["l3"])
	w("\t%s\tl5+%d(FP), R4", movPtr, args["l5"])
	w("\tMOVD\t$%d, R26", xBlock)
	w("\tMUL\tR1, R26, R26")
	w("\tADD\tR3, R26, R27")
	w("\tCMP\tR27, R21")
	w("\tBLO\t%s", oob)
	w("\tMOVD\t$%d, R26", yBlock)
	w("\tMUL\tR1, R26, R26")
	w("\tADD\tR4, R26, R27")
	w("\tCMP\tR27, R21")
	w("\tBLO\t%s", oob)
	w("\tADD\tR20, R3, R3")
	w("\tADD\tR20, R4, R4")
}

// --- tile helpers (nrc == 2 kernels).

// insS: d.s[di] = n.s[ni].
func (e *a64Q) insS(d, di, n, ni int) {
	e.word(0x6E000400|uint32(di<<3|4)<<16|uint32(ni<<2)<<11|uint32(n)<<5|uint32(d), fmt.Sprintf("mov v%d.s[%d], v%d.s[%d]", d, di, n, ni))
}

func (e *a64Q) zip1_4s(d, n, m int) {
	e.word(0x4E803800|lane3(d, n, m), fmt.Sprintf("zip1 v%d.4s, v%d.4s, v%d.4s", d, n, m))
}

// dup2d: d.2d = n.d[idx] (both 64-bit lanes).
func (e *a64Q) dup2d(d, n, idx int) {
	e.word(0x4E000400|uint32(idx<<4|8)<<16|uint32(n)<<5|uint32(d), fmt.Sprintf("dup v%d.2d, v%d.d[%d]", d, n, idx))
}

func (e *a64Q) fmul4s(d, n, m int) {
	e.word(0x6E20DC00|lane3(d, n, m), fmt.Sprintf("fmul v%d.4s, v%d.4s, v%d.4s", d, n, m))
}

func (e *a64Q) fmla4s(d, n, m int) {
	e.word(0x4E20CC00|lane3(d, n, m), fmt.Sprintf("fmla v%d.4s, v%d.4s, v%d.4s", d, n, m))
}

func (e *a64Q) fmls4s(d, n, m int) {
	e.word(0x4EA0CC00|lane3(d, n, m), fmt.Sprintf("fmls v%d.4s, v%d.4s, v%d.4s", d, n, m))
}

func (e *a64Q) shl4s(d, n, imm int) {
	e.word(0x4F005400|uint32(32|imm)<<16|uint32(n)<<5|uint32(d), fmt.Sprintf("shl v%d.4s, v%d.4s, #%d", d, n, imm))
}

func (e *a64Q) sub4s(d, n, m int) {
	e.word(0x6EA08400|lane3(d, n, m), fmt.Sprintf("sub v%d.4s, v%d.4s, v%d.4s", d, n, m))
}
