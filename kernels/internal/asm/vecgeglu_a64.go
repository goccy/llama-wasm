package asm

import (
	"encoding/binary"
	"fmt"
	"math"
	"strings"
)

// vecGegluConsts is the GeGLU-erf kernels' constant blob: the
// Abramowitz & Stegun 7.1.26 coefficients a1..a5 and p, the 0.5 of the
// GELU, 1/sqrt(2), and the f32 sign mask (see ggml_vec_geglu_erf_f32 in
// llama-wasm's vec.cpp patch, whose arithmetic both bodies mirror).
func vecGegluConsts() []byte {
	f := []float32{
		0.254829592, -0.284496736, 1.421413741, -1.453152027,
		1.061405429, 0.3275911, 0.5, 0.70710678118654752440084436210484,
	}
	blob := make([]byte, 48)
	for i, v := range f {
		binary.LittleEndian.PutUint32(blob[4*i:], math.Float32bits(v))
	}
	for i := 8; i < 12; i++ {
		binary.LittleEndian.PutUint32(blob[4*i:], 0x80000000)
	}
	return blob
}

// a64VecGegluErfKernel emits ggml_vec_geglu_erf_f32 under sym:
// y[i] = 0.5*x[i]*(1 + erf(x[i]/sqrt(2)))*g[i], erf by A&S 7.1.26 with
// exp through the shared ggml_v_expf nest. Same argument frame as the
// SwiGLU kernel (n, y, x, g).
func a64VecGegluErfKernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	e := &a64VecExp{}
	e.w = func(format string, args ...any) { fmt.Fprintf(&sb, format+"\n", args...) }
	e.word = func(enc uint32, dis string) { e.w("\tWORD $0x%08x // %s", enc, dis) }
	cSym := pool.addBlob(vecExpConsts())
	gSym := pool.addBlob(vecGegluConsts())
	_, _, args, _ := vecExpArgs(wide)
	movPtr := "MOVWU"
	if wide {
		movPtr = "MOVD"
	}
	w := e.w
	fneg := func(d, n int) {
		e.word(0x6EA0F800|uint32(n)<<5|uint32(d), fmt.Sprintf("fneg v%d.4s, v%d.4s", d, n))
	}
	fabs := func(d, n int) {
		e.word(0x4EA0F800|uint32(n)<<5|uint32(d), fmt.Sprintf("fabs v%d.4s, v%d.4s", d, n))
	}
	fmls := func(d, n, m int) {
		e.word(0x4EA0CC00|uint32(m)<<16|uint32(n)<<5|uint32(d), fmt.Sprintf("fmls v%d.4s, v%d.4s, v%d.4s", d, n, m))
	}
	and := func(d, n, m int) {
		e.word(0x4E201C00|uint32(m)<<16|uint32(n)<<5|uint32(d), fmt.Sprintf("and v%d.16b, v%d.16b, v%d.16b", d, n, m))
	}
	orr := func(d, n, m int) {
		e.word(0x4EA01C00|uint32(m)<<16|uint32(n)<<5|uint32(d), fmt.Sprintf("orr v%d.16b, v%d.16b, v%d.16b", d, n, m))
	}
	w("// %s: y = 0.5*x*(1 + erf(x/sqrt2))*g, erf by A&S 7.1.26.", sym)
	w("\tMOVW\tl0+%d(FP), R1", args["l0"])
	w("\tCMPW\t$1, R1")
	w("\tBLT\tgedone")
	w("\t%s\tl1+%d(FP), R2", movPtr, args["l1"])
	w("\t%s\tl2+%d(FP), R3", movPtr, args["l2"])
	w("\t%s\tl3+%d(FP), R4", movPtr, args["l3"])
	w("\tLSL\t$2, R1, R26")
	for _, r := range []int{2, 3, 4} {
		w("\tADD\tR%d, R26, R27", r)
		w("\tCMP\tR27, R21")
		w("\tBLO\tgeoob")
	}
	w("\tADD\tR20, R2, R2")
	w("\tADD\tR20, R3, R3")
	w("\tADD\tR20, R4, R4")
	e.loadConsts(cSym, 5)
	// v14 = [a1 a2 a3 a4], v15 = [a5 p half 1/sqrt2], v16 = sign mask.
	w("\tMOVD\t$·%s(SB), R6", gSym)
	w("\tVLD1\t(R6), [V14.S4, V15.S4, V16.S4]")
	one := e.c(25)
	// x in v13, g in v12; the exp nest clobbers v0..v11.
	body := func() {
		e.fmulLane(17, 13, 15, 3) // z = x/sqrt2
		fabs(18, 17)              // az = |z|
		e.fmulV(0, 18, 18)
		fneg(0, 0)
		e.exp(0, 0) // e = exp(-az^2)
		e.mov(1, one)
		e.fmlaLane(1, 18, 15, 1) // u = 1 + p*az
		e.fdivV(2, one, 1)       // t = 1/u
		e.dupLane(3, 15, 0)      // acc = a5
		e.dupLane(4, 14, 3)
		e.fmlaV(4, 2, 3) // a4 + t*acc
		e.dupLane(3, 14, 2)
		e.fmlaV(3, 2, 4) // a3 + t*acc
		e.dupLane(4, 14, 1)
		e.fmlaV(4, 2, 3) // a2 + t*acc
		e.dupLane(3, 14, 0)
		e.fmlaV(3, 2, 4) // a1 + t*acc
		e.fmulV(4, 2, 3) // poly = t*acc
		e.mov(5, one)
		fmls(5, 4, 0)  // erfa = 1 - poly*e
		and(6, 17, 16) // sign of z
		orr(5, 5, 6)   // erf = copysign(erfa, z)
		e.faddV(7, 5, one)
		e.fmulV(7, 7, 13)
		e.fmulLane(7, 7, 15, 2) // *0.5
		e.fmulV(7, 7, 12)       // *g
	}
	w("geloop4:")
	w("\tCMPW\t$4, R1")
	w("\tBLT\tgetail")
	e.ldurQ(13, 3, 0)
	e.ldurQ(12, 4, 0)
	body()
	e.sturQ(7, 2, 0)
	w("\tADD\t$16, R2, R2")
	w("\tADD\t$16, R3, R3")
	w("\tADD\t$16, R4, R4")
	w("\tSUBW\t$4, R1, R1")
	w("\tB\tgeloop4")
	w("getail:")
	w("\tCBZW\tR1, gedone")
	w("\tFMOVS\t(R3), F13")
	w("\tFMOVS\t(R4), F12")
	body()
	w("\tFMOVS\tF7, (R2)")
	w("\tADD\t$4, R2, R2")
	w("\tADD\t$4, R3, R3")
	w("\tADD\t$4, R4, R4")
	w("\tSUBW\t$1, R1, R1")
	w("\tB\tgetail")
	w("gedone:")
	w("\tRET")
	w("geoob:")
	w("\tB\tovr_oob")
	return sb.String()
}
