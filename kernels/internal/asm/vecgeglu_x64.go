package asm

import (
	"encoding/binary"
	"fmt"
	"math"
	"strings"
)

// x64VecGegluErfKernel emits ggml_vec_geglu_erf_f32 under sym (AVX2):
// y = 0.5*x*(1 + erf(x/sqrt2))*g with erf by A&S 7.1.26, exp through
// the shared ggml_v_expf nest; same frame as the SwiGLU kernel.
func x64VecGegluErfKernel(sym string, pool *ConstPool, wide bool) string {
	var sb strings.Builder
	w := func(format string, args ...any) { fmt.Fprintf(&sb, format+"\n", args...) }
	e := newX64VecExp(w, pool)
	rep := func(name string, bits uint32) {
		blob := make([]byte, 32)
		for i := 0; i < 8; i++ {
			binary.LittleEndian.PutUint32(blob[4*i:], bits)
		}
		e.c[name] = pool.addBlob(blob)
	}
	f := func(name string, v float32) { rep(name, math.Float32bits(v)) }
	f("ge_a1", 0.254829592)
	f("ge_a2", -0.284496736)
	f("ge_a3", 1.421413741)
	f("ge_a4", -1.453152027)
	f("ge_a5", 1.061405429)
	f("ge_p", 0.3275911)
	f("ge_half", 0.5)
	f("ge_s2i", 0.70710678118654752440084436210484)
	rep("ge_sign", 0x80000000)
	_, _, args, _ := vecExpArgs(wide)
	movPtr := "MOVL"
	if wide {
		movPtr = "MOVQ"
	}
	w("// %s: y = 0.5*x*(1 + erf(x/sqrt2))*g, erf by A&S 7.1.26.", sym)
	w("\tMOVLQSX\tl0+%d(FP), CX", args["l0"])
	w("\tTESTQ\tCX, CX")
	w("\tJLE\tgedone")
	w("\t%s\tl1+%d(FP), DI", movPtr, args["l1"])
	w("\t%s\tl2+%d(FP), SI", movPtr, args["l2"])
	w("\t%s\tl3+%d(FP), DX", movPtr, args["l3"])
	for _, reg := range []string{"DI", "SI", "DX"} {
		w("\tLEAQ\t(%s)(CX*4), R8", reg)
		w("\tCMPQ\tR15, R8")
		w("\tJCS\tgeoob")
	}
	w("\tADDQ\tR14, DI")
	w("\tADDQ\tR14, SI")
	w("\tADDQ\tR14, DX")
	// 13 keeps x, 12 the gate, 14 z, 15 |z|; the exp nest clobbers 0..11.
	body := func(W string, load, store string, step int, next string, lbl string) {
		w("%s:", lbl)
		if step > 1 {
			w("\tCMPQ\tCX, $%d", step)
			w("\tJLT\t%s", next)
		} else {
			w("\tTESTQ\tCX, CX")
			w("\tJZ\t%s", next)
		}
		w("\t%s\t(SI), %s13", load, W)
		w("\t%s\t(DX), %s12", load, W)
		w("\tVMULPS\t%s, %s13, %s14", e.sym("ge_s2i"), W, W) // z
		w("\tVANDPS\t%s, %s14, %s15", e.sym("abs"), W, W)    // az
		w("\tVMULPS\t%s15, %s15, %s0", W, W, W)
		w("\tVXORPS\t%s, %s0, %s0", e.sym("ge_sign"), W, W) // -az^2
		e.exp(W, 0, 0)                                      // e
		w("\tVMULPS\t%s, %s15, %s1", e.sym("ge_p"), W, W)
		w("\tVADDPS\t%s, %s1, %s1", e.sym("one"), W, W) // u = 1 + p*az
		w("\tVMOVUPS\t%s, %s2", e.sym("one"), W)
		w("\tVDIVPS\t%s1, %s2, %s2", W, W, W) // t = 1/u
		w("\tVMOVUPS\t%s, %s3", e.sym("ge_a5"), W)
		for _, a := range []string{"ge_a4", "ge_a3", "ge_a2", "ge_a1"} {
			w("\tVMULPS\t%s2, %s3, %s3", W, W, W)
			w("\tVADDPS\t%s, %s3, %s3", e.sym(a), W, W)
		}
		w("\tVMULPS\t%s2, %s3, %s4", W, W, W) // poly = t*acc
		w("\tVMULPS\t%s0, %s4, %s4", W, W, W)
		w("\tVMOVUPS\t%s, %s5", e.sym("one"), W)
		w("\tVSUBPS\t%s4, %s5, %s5", W, W, W) // erfa = 1 - poly*e
		w("\tVANDPS\t%s, %s14, %s6", e.sym("ge_sign"), W, W)
		w("\tVORPS\t%s6, %s5, %s5", W, W, W) // erf = copysign(erfa, z)
		w("\tVADDPS\t%s, %s5, %s7", e.sym("one"), W, W)
		w("\tVMULPS\t%s13, %s7, %s7", W, W, W)
		w("\tVMULPS\t%s, %s7, %s7", e.sym("ge_half"), W, W)
		w("\tVMULPS\t%s12, %s7, %s7", W, W, W)
		w("\t%s\t%s7, (DI)", store, W)
		w("\tADDQ\t$%d, DI", 4*step)
		w("\tADDQ\t$%d, SI", 4*step)
		w("\tADDQ\t$%d, DX", 4*step)
		w("\tSUBQ\t$%d, CX", step)
		w("\tJMP\t%s", lbl)
	}
	body("Y", "VMOVUPS", "VMOVUPS", 8, "geloop4", "geloop8")
	body("X", "VMOVUPS", "VMOVUPS", 4, "getail", "geloop4")
	body("X", "VMOVSS", "VMOVSS", 1, "gedone", "getail")
	w("gedone:")
	w("\tVZEROUPPER")
	w("\tRET")
	w("geoob:")
	w("\tVZEROUPPER")
	w("\tJMP\tovr_oob")
	return sb.String()
}
