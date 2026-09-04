package asm

import (
	"strings"
	"testing"
)

func TestFlashAttnKernelShape(t *testing.T) {
	a := a64FlashAttnKernel("FnAneon", NewConstPool("t_"), true)
	for _, want := range []string{"ldr q3, [x13], #16", "fmadd s1, s1, s14, s17", "fcmp s1, s13", "fanewmax:", "famadloop:", "fmla v9.4s, v5.4s, v19.s[0]", "str s13, [x10, #4]", "l0+8(FP), R0", "MOVW\t88(R0), R1", "FMOVS\t84(R0), F14", "ldr h17, [x8], #2"} {
		if !strings.Contains(a, want) {
			t.Errorf("a64 flash-attn kernel missing %q", want)
		}
	}
	if _, n := flashAttnArgs(true); n != 16 {
		t.Errorf("wide frame %d", n)
	}
}

// flashAttnRunSrc: a float64 reference of ggml's single-query KV loop
// (exact expf, exact f16 values) against the kernel over head sizes,
// position counts, strided rows, masks with -inf entries and a resumed
// online-softmax state.
const flashAttnRunSrc = `package attnrun

import (
	"math"
	"testing"
	"unsafe"
)

type mockModule struct {
	memSizePtr *uint64
	mem        unsafe.Pointer
}

func f16bits(f float32) uint16 {
	b := math.Float32bits(f)
	sign := uint16(b>>16) & 0x8000
	exp := int((b>>23)&0xff) - 127 + 15
	mant := b & 0x7fffff
	if exp <= 0 {
		return sign
	}
	if exp >= 31 {
		return sign | 0x7c00
	}
	return sign | uint16(exp)<<10 | uint16(mant>>13)
}

func f16val(h uint16) float64 {
	if h == 0xfc00 {
		return math.Inf(-1)
	}
	sign := 1.0
	if h&0x8000 != 0 {
		sign = -1
	}
	exp := int(h>>10) & 0x1f
	mant := float64(h & 0x3ff)
	if exp == 0 {
		return sign * mant * math.Pow(2, -24)
	}
	return sign * (1 + mant/1024) * math.Pow(2, float64(exp-15))
}

func put16(mem []byte, off int, h uint16) { mem[off] = byte(h); mem[off+1] = byte(h >> 8) }
func put32(mem []byte, off int, f float32) {
	b := math.Float32bits(f)
	mem[off], mem[off+1], mem[off+2], mem[off+3] = byte(b), byte(b>>8), byte(b>>16), byte(b>>24)
}
func get32(mem []byte, off int) float32 {
	return math.Float32frombits(uint32(mem[off]) | uint32(mem[off+1])<<8 | uint32(mem[off+2])<<16 | uint32(mem[off+3])<<24)
}

type lcg uint32

func (s *lcg) next() uint32 { *s = *s*1664525 + 1013904223; return uint32(*s) }
func (s *lcg) unit() float64 { return float64(s.next()>>8)/float64(1<<24)*2 - 1 }

func close64(got float32, want float64, tolRel float64) bool {
	d := math.Abs(float64(got) - want)
	return d <= tolRel*math.Max(1e-3, math.Abs(want))
}

type attnKernel func(m *mockModule, l0 int64)

func put64(mem []byte, off int, v uint64) {
	for i := 0; i < 8; i++ {
		mem[off+i] = byte(v >> (8 * i))
	}
}

// runAttn builds one query against n KV rows (strided by pad bytes),
// runs the kernel over [start, n) and checks S, M and VKQ against the
// float64 loop. withMask sets every 7th position to -inf and the rest
// to small values; resume starts from a non-empty state.
func runAttn(t *testing.T, kernel attnKernel, DK, DV, n, start, pad int, withMask, resume bool, seed uint32) {
	t.Helper()
	s := lcg(seed)
	nbk := 2*DK + pad
	nbv := 2*DV + pad
	qOff := 256
	kOff := qOff + 2*DK + 64
	vOff := kOff + n*nbk + 64
	mOff := vOff + n*nbv + 64
	smOff := mOff + 2*n + 64
	vkqOff := smOff + 64
	argOff := vkqOff + 4*DV + 64
	mem := make([]byte, argOff+96+256)
	q := make([]float64, DK)
	for i := range q {
		h := f16bits(float32(s.unit() * 0.5))
		put16(mem, qOff+2*i, h)
		q[i] = f16val(h)
	}
	k := make([][]float64, n)
	v := make([][]float64, n)
	mask := make([]float64, n)
	for p := 0; p < n; p++ {
		k[p] = make([]float64, DK)
		v[p] = make([]float64, DV)
		for i := 0; i < DK; i++ {
			h := f16bits(float32(s.unit() * 0.5))
			put16(mem, kOff+p*nbk+2*i, h)
			k[p][i] = f16val(h)
		}
		for i := 0; i < DV; i++ {
			h := f16bits(float32(s.unit()))
			put16(mem, vOff+p*nbv+2*i, h)
			v[p][i] = f16val(h)
		}
		var h uint16
		if withMask {
			if p%7 == 3 {
				h = 0xfc00
			} else {
				h = f16bits(float32(s.unit() * 0.25))
			}
		}
		put16(mem, mOff+2*p, h)
		mask[p] = f16val(h)
	}
	S, M := 0.0, math.Inf(-1)
	vkq := make([]float64, DV)
	if resume {
		S, M = 3.25, 0.75
		for i := range vkq {
			vkq[i] = s.unit()
			put32(mem, vkqOff+4*i, float32(vkq[i]))
			vkq[i] = float64(float32(vkq[i]))
		}
	}
	put32(mem, smOff, float32(S))
	put32(mem, smOff+4, float32(M))
	slope, scale := float32(1.0), float32(0.125)
	if withMask {
		slope = 0.5
	}
	mp := int64(0)
	if withMask {
		mp = int64(mOff)
	}
	memSize := uint64(len(mem))
	m := &mockModule{memSizePtr: &memSize, mem: unsafe.Pointer(&mem[0])}
	put64(mem, argOff+0, uint64(qOff))
	put64(mem, argOff+8, uint64(kOff))
	put64(mem, argOff+16, uint64(nbk))
	put64(mem, argOff+24, uint64(vOff))
	put64(mem, argOff+32, uint64(nbv))
	put64(mem, argOff+40, uint64(mp))
	put64(mem, argOff+48, uint64(smOff))
	put64(mem, argOff+56, uint64(vkqOff))
	put64(mem, argOff+64, uint64(start))
	put64(mem, argOff+72, uint64(n))
	put32(mem, argOff+80, slope)
	put32(mem, argOff+84, scale)
	put64(mem, argOff+88, uint64(uint32(DK))|uint64(uint32(DV))<<32)
	kernel(m, int64(argOff))
	// reference
	for p := start; p < n; p++ {
		mv := 0.0
		if withMask {
			mv = float64(slope) * mask[p]
		}
		if math.IsInf(mv, -1) {
			continue
		}
		dot := 0.0
		for i := 0; i < DK; i++ {
			dot += k[p][i] * q[i]
		}
		sv := dot*float64(scale) + mv
		ms, vs := 1.0, 1.0
		if sv > M {
			ms = math.Exp(M - sv)
			M = sv
			for i := range vkq {
				vkq[i] *= ms
			}
		} else {
			vs = math.Exp(sv - M)
		}
		for i := range vkq {
			vkq[i] += vs * v[p][i]
		}
		S = S*ms + vs
	}
	desc := "DK=" + itoa(DK) + " DV=" + itoa(DV) + " n=" + itoa(n) + " start=" + itoa(start)
	if got := get32(mem, smOff); !close64(got, S, 2e-5) {
		t.Fatalf("%s: S = %v, want %v", desc, got, S)
	}
	if got := get32(mem, smOff+4); !close64(got, M, 1e-6) {
		t.Fatalf("%s: M = %v, want %v", desc, got, M)
	}
	// VKQ sums n terms of magnitude up to vs*|v| <= 1 in f32 (the wasm
	// body does the same), so the bar is set against that magnitude,
	// not the (possibly cancelled) result.
	for i := 0; i < DV; i++ {
		if got := get32(mem, vkqOff+4*i); math.Abs(float64(got)-vkq[i]) > 1e-4*math.Max(1, math.Abs(vkq[i])) {
			t.Fatalf("%s: VKQ[%d] = %v, want %v", desc, i, got, vkq[i])
		}
	}
	// nothing else written
	for off := 0; off < len(mem); off++ {
		if off >= smOff && off < smOff+8 || off >= vkqOff && off < vkqOff+4*DV {
			continue
		}
		var want byte
		switch {
		case off >= qOff && off < qOff+2*DK, off >= kOff && off < kOff+n*nbk, off >= vOff && off < vOff+n*nbv, off >= mOff && off < mOff+2*n, off >= argOff && off < argOff+96:
			continue
		}
		if mem[off] != want {
			t.Fatalf("%s: byte %d written", desc, off)
		}
	}
}

func itoa(i int) string {
	if i == 0 {
		return "0"
	}
	var b []byte
	for i > 0 {
		b = append([]byte{byte('0' + i%10)}, b...)
		i /= 10
	}
	return string(b)
}
`

const flashAttnDecls = "\nfunc AttnKernel(m *mockModule, l0 int64)\nfunc trapstub()\n\nvar _ = trapstub\n"

const flashAttnRunTest = `package attnrun

import "testing"

func TestFlashAttn(t *testing.T) {
	seed := uint32(7)
	for _, d := range [][2]int{{64, 64}, {128, 128}, {16, 32}, {80, 64}} {
		for _, n := range []int{1, 2, 5, 64, 301} {
			for _, start := range []int{0, 3} {
				if start >= n {
					continue
				}
				for _, pad := range []int{0, 32} {
					for _, withMask := range []bool{false, true} {
						for _, resume := range []bool{false, true} {
							seed++
							runAttn(t, AttnKernel, d[0], d[1], n, start, pad, withMask, resume, seed)
						}
					}
				}
			}
		}
	}
	// an empty range leaves the state alone
	runAttn(t, AttnKernel, 64, 64, 4, 4, 0, false, true, 99)
}
`

func TestA64FlashAttnKernelGate(t *testing.T) {
	_, argBytes := flashAttnArgs(true)
	pool := NewConstPool("fa_")
	body := a64FlashAttnKernel("AttnKernel", pool, true) + "\n" + pool.Emit()
	asm := wrap("arm64", "AttnKernel", 16, argBytes, "neon", body)
	dir := t.TempDir()
	writeRunTree(t, dir, "attnrun", "arm64", asm, flashAttnRunSrc+flashAttnDecls, flashAttnRunTest)
	runArm64Gate(t, dir, ".", "TestFlashAttn", asm)
}
