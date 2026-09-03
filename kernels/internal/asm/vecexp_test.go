package asm

import (
	"strings"
	"testing"
)

func TestVecExpKernelShape(t *testing.T) {
	pool := &ConstPool{}
	a := a64VecSoftMaxKernel("Fn13dotprod", pool, true)
	for _, want := range []string{"fmla v1.4s, v0.4s, v28.s[1]", "shl v4.4s, v1.4s, #23", "bsl v7.16b", "faddp s1, v1.2s", "FCVTSD", "r0+40(FP)"} {
		if !strings.Contains(a, want) {
			t.Errorf("a64 soft_max missing %q", want)
		}
	}
	if s := a64VecSwigluKernel("Fn14dotprod", pool, true); !strings.Contains(s, "fdiv v0.4s, v13.4s, v0.4s") {
		t.Error("a64 swiglu shape")
	}
	x := x64VecSoftMaxKernel("Fn13avx2", pool, true)
	for _, want := range []string{"VFMADD231PS", "VPSLLD\t$23", "VBLENDVPS", "VCVTSS2SD", "r0+40(FP)", "VZEROUPPER"} {
		if !strings.Contains(x, want) {
			t.Errorf("x64 soft_max missing %q", want)
		}
	}
	if s := x64VecSwigluKernel("Fn14avx2", pool, true); !strings.Contains(s, "VDIVPS") {
		t.Error("x64 swiglu shape")
	}
	if !strings.Contains(pool.Emit(), "GLOBL") {
		t.Error("constant pool empty")
	}
}

// vecExpRunSrc drives both kernels against float64 references: values
// must agree to a few ulps (the polynomial's own error plus fused
// rounding), the sum within 1e-6 relative, and out-of-range inputs
// must flush exactly as the reference does.
const vecExpRunSrc = `package exprun

import (
	"math"
	"testing"
	"unsafe"
)

type mockModule struct {
	memSizePtr *uint64
	mem        unsafe.Pointer
}

func putF32(mem []byte, off int, f float32) {
	b := math.Float32bits(f)
	mem[off], mem[off+1], mem[off+2], mem[off+3] = byte(b), byte(b>>8), byte(b>>16), byte(b>>24)
}

func getF32(mem []byte, off int) float32 {
	return math.Float32frombits(uint32(mem[off]) | uint32(mem[off+1])<<8 | uint32(mem[off+2])<<16 | uint32(mem[off+3])<<24)
}

func inputs(n int, seed uint32) []float32 {
	rng := seed
	out := make([]float32, n)
	for i := range out {
		rng = rng*1664525 + 1013904223
		switch i % 11 {
		case 0:
			out[i] = float32(math.Inf(-1))
		case 1:
			out[i] = -110 - float32(rng>>28)
		case 2:
			out[i] = -90 + float32(rng>>28)
		case 3:
			out[i] = 0
		default:
			out[i] = float32(int32(rng>>8)%20001-10000) / 500 // [-20, 20]
		}
	}
	return out
}

func close32(got float32, want float64, tolRel float64) bool {
	if math.IsInf(want, 1) {
		return math.IsInf(float64(got), 1)
	}
	if want == 0 {
		return got == 0
	}
	if math.Abs(want) < 1.2e-38 {
		// Subnormal results: the scaled special path of the polynomial
		// (as in ggml's own kernels) carries a few subnormal ulps of
		// error; the ulp there is 2^-149.
		return math.Abs(float64(got)-want) <= 8*1.401298464324817e-45
	}
	return math.Abs(float64(got)-want) <= tolRel*math.Abs(want)
}

func runSoftMax(t *testing.T, kernel func(m *mockModule, l0 int32, l1, l2 int64, l3 float32) float64, n int) {
	t.Helper()
	x := inputs(n, uint32(n)*7919+1)
	mem := make([]byte, 4096+8*n*4)
	xOff, yOff := 256, 256+n*4+64
	for i, v := range x {
		putF32(mem, xOff+4*i, v)
	}
	memSize := uint64(len(mem))
	m := &mockModule{memSizePtr: &memSize, mem: unsafe.Pointer(&mem[0])}
	const max = float32(3.25)
	sum := kernel(m, int32(n), int64(yOff), int64(xOff), max)
	var want float64
	for i, v := range x {
		w := math.Exp(float64(v) - float64(max))
		if float64(v)-float64(max) < -103.97 {
			w = 0
		}
		got := getF32(mem, yOff+4*i)
		if !close32(got, w, 4e-6) {
			t.Fatalf("n=%d y[%d] = %v, want %v (x=%v)", n, i, got, w, v)
		}
		want += float64(got)
	}
	if math.Abs(sum-want) > 1e-6*math.Max(1, math.Abs(want)) {
		t.Fatalf("n=%d sum = %v, want %v", n, sum, want)
	}
	for off := yOff + 4*n; off < len(mem); off++ {
		if mem[off] != 0 {
			t.Fatalf("n=%d byte %d past y written", n, off)
		}
	}
}

func runSwiglu(t *testing.T, kernel func(m *mockModule, l0 int32, l1, l2, l3 int64), n int) {
	t.Helper()
	x := inputs(n, uint32(n)*31+5)
	g := inputs(n, uint32(n)*17+3)
	for i := range x {
		if math.IsInf(float64(x[i]), 0) {
			x[i] = -50
		}
		if math.IsInf(float64(g[i]), 0) {
			g[i] = 2
		}
	}
	mem := make([]byte, 4096+12*n*4)
	xOff := 256
	gOff := xOff + n*4 + 64
	yOff := gOff + n*4 + 64
	for i := range x {
		putF32(mem, xOff+4*i, x[i])
		putF32(mem, gOff+4*i, g[i])
	}
	memSize := uint64(len(mem))
	m := &mockModule{memSizePtr: &memSize, mem: unsafe.Pointer(&mem[0])}
	kernel(m, int32(n), int64(yOff), int64(xOff), int64(gOff))
	for i := range x {
		w := float64(x[i]) / (1 + math.Exp(-float64(x[i]))) * float64(g[i])
		got := getF32(mem, yOff+4*i)
		if math.Abs(float64(got)-w) > 4e-6*math.Abs(w)+1e-30 {
			t.Fatalf("n=%d y[%d] = %v, want %v (x=%v g=%v)", n, i, got, w, x[i], g[i])
		}
	}
}
`

const vecExpDecls = "\nfunc SoftMaxKernel(m *mockModule, l0 int32, l1, l2 int64, l3 float32) float64\nfunc SwigluKernel(m *mockModule, l0 int32, l1, l2, l3 int64)\nfunc trapstub()\n\nvar _ = trapstub\n"

const vecExpRunTest = `package exprun

import "testing"

func TestVecExp(t *testing.T) {
	for _, n := range []int{64, 1, 3, 4, 7, 9, 15, 16, 4864} {
		runSoftMax(t, SoftMaxKernel, n)
		runSwiglu(t, SwigluKernel, n)
	}
}
`

func TestA64VecExpKernelGate(t *testing.T) {
	_, smBytes, _, swBytes := vecExpArgs(true)
	pool := &ConstPool{}
	asm := wrap("arm64", "SoftMaxKernel", 16, smBytes, "neon", a64VecSoftMaxKernel("SoftMaxKernel", pool, true)) +
		wrap("arm64", "SwigluKernel", 16, swBytes, "neon", a64VecSwigluKernel("SwigluKernel", pool, true)) + pool.Emit()
	dir := t.TempDir()
	writeRunTree(t, dir, "exprun", "arm64", asm, vecExpRunSrc+vecExpDecls, vecExpRunTest)
	runArm64Gate(t, dir, ".", "TestVecExp", asm)
}

func TestX64VecExpKernelGate(t *testing.T) {
	_, smBytes, _, swBytes := vecExpArgs(true)
	pool := &ConstPool{}
	asm := wrap("amd64", "SoftMaxKernel", 16, smBytes, "avx2", x64VecSoftMaxKernel("SoftMaxKernel", pool, true)) +
		wrap("amd64", "SwigluKernel", 16, swBytes, "avx2", x64VecSwigluKernel("SwigluKernel", pool, true)) + pool.Emit()
	dir := t.TempDir()
	writeRunTree(t, dir, "exprun", "amd64", asm, vecExpRunSrc+vecExpDecls, vecExpRunTest)
	runAmd64Gate(t, dir, ".", "TestVecExp", asm)
}
