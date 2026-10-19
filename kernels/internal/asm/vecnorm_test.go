package asm

import (
	"strings"
	"testing"
)

func TestVecNormKernelsEmit(t *testing.T) {
	pool := &ConstPool{}
	if s := a64VecSumKernel("Fn20neon", pool, true); !strings.Contains(s, "faddp") || !strings.Contains(s, "FCVTSD") {
		t.Fatalf("a64 sum body:\n%s", s)
	}
	if s := a64VecCvarKernel("Fn21neon", pool, true); !strings.Contains(s, "fsub") || !strings.Contains(s, "FDIVD") {
		t.Fatalf("a64 cvar body:\n%s", s)
	}
	if s := x64VecSumKernel("Fn20avx2", pool, true); !strings.Contains(s, "VHADDPS") {
		t.Fatalf("x64 sum body:\n%s", s)
	}
	if s := x64VecCvarKernel("Fn21avx2", pool, true); !strings.Contains(s, "VDIVSD") {
		t.Fatalf("x64 cvar body:\n%s", s)
	}
}

const vecNormRunSrc = `package normrun

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

// rowInputs is a LayerNorm-like row: values in [-6, 6] with a few
// outliers, no infinities.
func rowInputs(n int, seed uint32) []float32 {
	rng := seed
	out := make([]float32, n)
	for i := range out {
		rng = rng*1664525 + 1013904223
		out[i] = float32(int32(rng>>8)%12001-6000) / 1000
		if i%37 == 5 {
			out[i] *= 40
		}
	}
	return out
}

// groupSum is the C body's reduction: four lanes as (l0+l1)+(l2+l3) in
// float32, widened per group, the tail element by element.
func groupSum(v []float32) float64 {
	var sum float64
	i := 0
	for ; i+3 < len(v); i += 4 {
		sum += float64((v[i] + v[i+1]) + (v[i+2] + v[i+3]))
	}
	for ; i < len(v); i++ {
		sum += float64(v[i])
	}
	return sum
}

func runSum(t *testing.T, kernel func(m *mockModule, l0 int32, l1 int64) float64, n int) {
	t.Helper()
	x := rowInputs(n, uint32(n)*101+3)
	mem := make([]byte, 4096+4*n*4)
	xOff := 256
	for i, v := range x {
		putF32(mem, xOff+4*i, v)
	}
	memSize := uint64(len(mem))
	m := &mockModule{memSizePtr: &memSize, mem: unsafe.Pointer(&mem[0])}
	before := append([]byte(nil), mem...)
	got := kernel(m, int32(n), int64(xOff))
	if res := refCheck(t, kernel, before, mem, []refArg{rI32(int32(n)), rPtr(int64(xOff))}, nil, nil, refTolExp); res.has && math.Abs(res.f64-got) > 1e-9*math.Max(1, math.Abs(got)) {
		t.Fatalf("n=%d sum: asm %v, C body %v", n, got, res.f64)
	}
	want := groupSum(x)
	if math.Abs(got-want) > 1e-9*math.Max(1, math.Abs(want)) {
		t.Fatalf("n=%d sum = %v, want %v", n, got, want)
	}
	for i := range mem {
		if mem[i] != before[i] {
			t.Fatalf("n=%d byte %d written", n, i)
		}
	}
}

func runCvar(t *testing.T, kernel func(m *mockModule, l0 int32, l1, l2 int64, l3 float32) float64, n int) {
	t.Helper()
	x := rowInputs(n, uint32(n)*77+9)
	mem := make([]byte, 4096+8*n*4)
	xOff, yOff := 256, 256+n*4+64
	for i, v := range x {
		putF32(mem, xOff+4*i, v)
	}
	memSize := uint64(len(mem))
	m := &mockModule{memSizePtr: &memSize, mem: unsafe.Pointer(&mem[0])}
	mean := float32(groupSum(x) / float64(n))
	before := append([]byte(nil), mem...)
	got := kernel(m, int32(n), int64(yOff), int64(xOff), mean)
	if res := refCheck(t, kernel, before, mem, []refArg{rI32(int32(n)), rPtr(int64(yOff)), rPtr(int64(xOff)), rF32(mean)},
		nil, []refOut{outBytes(yOff, 4 * n)}, refTolExp); res.has && math.Abs(res.f64-got) > 1e-9*math.Max(1, math.Abs(got)) {
		t.Fatalf("n=%d cvar: asm %v, C body %v", n, got, res.f64)
	}
	sq := make([]float32, n)
	for i, v := range x {
		d := v - mean
		if y := getF32(mem, yOff+4*i); y != d {
			t.Fatalf("n=%d y[%d] = %v, want %v", n, i, y, d)
		}
		sq[i] = d * d
	}
	want := groupSum(sq) / float64(n)
	if math.Abs(got-want) > 1e-9*math.Max(1, math.Abs(want)) {
		t.Fatalf("n=%d cvar = %v, want %v", n, got, want)
	}
	for off := yOff + 4*n; off < len(mem); off++ {
		if mem[off] != 0 {
			t.Fatalf("n=%d byte %d past y written", n, off)
		}
	}
}
`

const vecNormDecls = "\nfunc SumKernel(m *mockModule, l0 int32, l1 int64) float64\nfunc CvarKernel(m *mockModule, l0 int32, l1, l2 int64, l3 float32) float64\n"

const vecNormRunTest = `package normrun

import "testing"

func TestVecNorm(t *testing.T) {
	for _, n := range []int{64, 1, 3, 4, 7, 8, 9, 15, 16, 17, 768, 4864} {
		runSum(t, SumKernel, n)
		runCvar(t, CvarKernel, n)
	}
}
`

func TestA64VecNormKernelGate(t *testing.T) {
	_, sumBytes := vecNormArgs(true)
	_, cvBytes, _, _ := vecExpArgs(true)
	pool := &ConstPool{}
	asm := wrap("arm64", "SumKernel", 16, sumBytes, "neon", a64VecSumKernel("SumKernel", pool, true)) +
		wrap("arm64", "CvarKernel", 16, cvBytes, "neon", a64VecCvarKernel("CvarKernel", pool, true)) + pool.Emit()
	dir := t.TempDir()
	writeRunTree(t, dir, "normrun", "arm64", asm, vecNormRunSrc+vecNormDecls, vecNormRunTest, "SumKernel", "dbg_vec_sum_f32", "CvarKernel", "dbg_vec_cvar_f32")
	runArm64Gate(t, dir, ".", "TestVecNorm", asm)
}

func TestX64VecNormKernelGate(t *testing.T) {
	_, sumBytes := vecNormArgs(true)
	_, cvBytes, _, _ := vecExpArgs(true)
	pool := &ConstPool{}
	asm := wrap("amd64", "SumKernel", 16, sumBytes, "avx2", x64VecSumKernel("SumKernel", pool, true)) +
		wrap("amd64", "CvarKernel", 16, cvBytes, "avx2", x64VecCvarKernel("CvarKernel", pool, true)) + pool.Emit()
	dir := t.TempDir()
	writeRunTree(t, dir, "normrun", "amd64", asm, vecNormRunSrc+vecNormDecls, vecNormRunTest, "SumKernel", "dbg_vec_sum_f32", "CvarKernel", "dbg_vec_cvar_f32")
	runAmd64Gate(t, dir, ".", "TestVecNorm", asm)
}
