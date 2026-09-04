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
	// M is one f32 score (an f32 dot of DK terms, fused with the scale):
	// a few ulps of the score magnitude.
	if got := get32(mem, smOff+4); math.Abs(float64(got)-M) > 1e-5*math.Max(1, math.Abs(M)) {
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

// runAttnLayout runs the kernel over n real positions from a fresh state,
// with one fully masked row (junk K and V, mask -inf) inserted before each
// real index listed in holes, and returns the bytes of S, M and VKQ. A
// masked position contributes nothing, so the result must not depend on
// holes: the kernel's block-of-eight schedule must not leak into the
// arithmetic (a unified KV cache places a sequence's cells at arbitrary
// offsets, and the same sequence must score identically wherever it sits).
func runAttnLayout(t *testing.T, kernel attnKernel, DK, DV, n int, holes []int, seed uint32) []byte {
	t.Helper()
	total := n + len(holes)
	s := lcg(seed)
	nbk, nbv := 2*DK, 2*DV
	qOff := 256
	kOff := qOff + 2*DK + 64
	vOff := kOff + total*nbk + 64
	mOff := vOff + total*nbv + 64
	smOff := mOff + 2*total + 64
	vkqOff := smOff + 64
	argOff := vkqOff + 4*DV + 64
	mem := make([]byte, argOff+96+256)
	for i := 0; i < DK; i++ {
		put16(mem, qOff+2*i, f16bits(float32(s.unit()*0.5)))
	}
	// the real rows come from the seed in order, so every layout sees the
	// same rows
	krow := make([][]uint16, n)
	vrow := make([][]uint16, n)
	mrow := make([]uint16, n)
	for r := 0; r < n; r++ {
		krow[r] = make([]uint16, DK)
		vrow[r] = make([]uint16, DV)
		for i := range krow[r] {
			krow[r][i] = f16bits(float32(s.unit() * 0.5))
		}
		for i := range vrow[r] {
			vrow[r][i] = f16bits(float32(s.unit()))
		}
		if r%5 == 2 {
			mrow[r] = f16bits(float32(s.unit() * 0.25))
		}
	}
	// a hole index of n (or beyond) appends the masked row after the last
	// real one
	junk := lcg(seed ^ 0x9e3779b9)
	p := 0
	for r := 0; r <= n; r++ {
		for _, h := range holes {
			if h > n {
				h = n
			}
			if h != r {
				continue
			}
			for i := 0; i < DK; i++ {
				put16(mem, kOff+p*nbk+2*i, f16bits(float32(junk.unit())))
			}
			for i := 0; i < DV; i++ {
				put16(mem, vOff+p*nbv+2*i, f16bits(float32(junk.unit())))
			}
			put16(mem, mOff+2*p, 0xfc00)
			p++
		}
		if r == n {
			break
		}
		for i := 0; i < DK; i++ {
			put16(mem, kOff+p*nbk+2*i, krow[r][i])
		}
		for i := 0; i < DV; i++ {
			put16(mem, vOff+p*nbv+2*i, vrow[r][i])
		}
		put16(mem, mOff+2*p, mrow[r])
		p++
	}
	put32(mem, smOff, 0)
	put32(mem, smOff+4, float32(math.Inf(-1)))
	memSize := uint64(len(mem))
	m := &mockModule{memSizePtr: &memSize, mem: unsafe.Pointer(&mem[0])}
	put64(mem, argOff+0, uint64(qOff))
	put64(mem, argOff+8, uint64(kOff))
	put64(mem, argOff+16, uint64(nbk))
	put64(mem, argOff+24, uint64(vOff))
	put64(mem, argOff+32, uint64(nbv))
	put64(mem, argOff+40, uint64(mOff))
	put64(mem, argOff+48, uint64(smOff))
	put64(mem, argOff+56, uint64(vkqOff))
	put64(mem, argOff+64, 0)
	put64(mem, argOff+72, uint64(total))
	put32(mem, argOff+80, 0.5)
	put32(mem, argOff+84, 0.125)
	put64(mem, argOff+88, uint64(uint32(DK))|uint64(uint32(DV))<<32)
	kernel(m, int64(argOff))
	out := make([]byte, 8+4*DV)
	copy(out, mem[smOff:smOff+8])
	copy(out[8:], mem[vkqOff:vkqOff+4*DV])
	return out
}
`

const flashAttnDecls = "\nfunc AttnKernel(m *mockModule, l0 int64)\nfunc trapstub()\n\nvar _ = trapstub\n"

const flashAttnRunTest = `package attnrun

import (
	"bytes"
	"testing"
)

func TestFlashAttn(t *testing.T) {
	seed := uint32(7)
	for _, d := range [][2]int{{64, 64}, {128, 128}, {16, 32}, {80, 64}, {8, 8}, {24, 40}, {72, 8}} {
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

// TestFlashAttnLayoutInvariance: masked rows inserted anywhere must leave
// S, M and VKQ bit-identical.
func TestFlashAttnLayoutInvariance(t *testing.T) {
	seed := uint32(101)
	for _, d := range [][2]int{{64, 64}, {128, 128}, {16, 32}, {24, 40}, {64, 128}} {
		for _, n := range []int{1, 3, 8, 13, 40} {
			seed++
			want := runAttnLayout(t, AttnKernel, d[0], d[1], n, nil, seed)
			for _, holes := range [][]int{{0}, {0, 0, 0}, {0, 0, 0, 0, 0, 0, 0}, {n / 2}, {1, 1, n - 1}, {n}, {n, n, n, n, n}, {0, 0, 0, 0, 0, n / 2, n / 2, n / 2, n}} {
				if got := runAttnLayout(t, AttnKernel, d[0], d[1], n, holes, seed); !bytes.Equal(got, want) {
					t.Fatalf("DK=%d DV=%d n=%d holes=%v: result depends on the layout of masked rows\n got %x\nwant %x", d[0], d[1], n, holes, got, want)
				}
			}
		}
	}
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

func TestX64FlashAttnKernelGate(t *testing.T) {
	_, argBytes := flashAttnArgs(true)
	pool := NewConstPool("fa_")
	body := x64FlashAttnKernel("AttnKernel", pool, true) + "\n" + pool.Emit()
	asm := wrap("amd64", "AttnKernel", x64FAFrame, argBytes, "avx2", body)
	dir := t.TempDir()
	writeRunTree(t, dir, "attnrun", "amd64", asm, flashAttnRunSrc+flashAttnDecls, flashAttnRunTest)
	runAmd64Gate(t, dir, ".", "TestFlashAttn", asm)
}

const flashAttnFHMRunSrc = `package attnrun

import (
	"math"
	"testing"
	"unsafe"
)

type mockModule struct {
	memSizePtr *uint64
	mem        unsafe.Pointer
}

// f16bits: f32 -> f16, round to nearest even (what FCVTN and FCVT do;
// the reference's every f16 rounding must match the hardware's).
func f16bits(f float32) uint16 {
	b := math.Float32bits(f)
	sign := uint16(b>>16) & 0x8000
	exp := int((b>>23)&0xff) - 127 + 15
	mant := b & 0x7fffff
	if exp <= 0 {
		if exp < -10 {
			return sign
		}
		mant |= 0x800000
		shift := uint(14 - exp)
		half := uint32(1) << (shift - 1)
		r := mant >> shift
		rem := mant & ((1 << shift) - 1)
		if rem > half || (rem == half && r&1 == 1) {
			r++
		}
		return sign | uint16(r)
	}
	if exp >= 31 {
		return sign | 0x7c00
	}
	r := mant >> 13
	rem := mant & 0x1fff
	if rem > 0x1000 || (rem == 0x1000 && r&1 == 1) {
		r++
	}
	return sign | uint16(exp)<<10 + uint16(r)
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


// fma32 is the arm64 fused multiply-add in f32 (one rounding).
func fma32(a, b, c float32) float32 { return float32(math.FMA(float64(a), float64(b), float64(c))) }

// expf32 is the kernel's expf (ggml_v_expf's arithmetic with fused
// multiply-adds, as vecexp_a64.go emits it), evaluated in f32.
func expf32(x float32) float32 {
	const (
		r     = float32(0x1.8p23)
		log2e = float32(0x1.715476p+0)
		c1    = float32(0x1.62e4p-1)
		c2    = float32(0x1.7f7d1cp-20)
		p0    = float32(0x1.0e4020p-7)
		p1    = float32(0x1.573e2ep-5)
		p2    = float32(0x1.555e66p-3)
		p3    = float32(0x1.fffdb6p-2)
		p4    = float32(0x1.ffffecp-1)
	)
	z := fma32(x, log2e, r)
	n := z - r
	b := fma32(-n, c1, x)
	b = fma32(-n, c2, b)
	e := math.Float32bits(z) << 23
	k := math.Float32frombits(e + math.Float32bits(1))
	an := float32(math.Abs(float64(n)))
	c := an > 126
	u := b * b
	t1 := fma32(b, p0, p1)
	t2 := fma32(b, p2, p3)
	t2 = fma32(t1, u, t2)
	m := p4 * b
	m = fma32(t2, u, m)
	res := fma32(m, k, k)
	var d uint32
	if n <= 0 {
		d = 0x82000000
	}
	s1 := math.Float32frombits(d + 0x7f000000)
	s2 := math.Float32frombits(e - d)
	alt := fma32(s2, m, s2) * s1
	big := s1 * s1
	switch {
	case an > 192:
		return big
	case c:
		return alt
	}
	return res
}

// f16of rounds a float64 to f16 (nearest even), the FCVTN/FCVT rounding.
func f16of(x float64) uint16 {
	if x == 0 || math.IsNaN(x) {
		return 0
	}
	sign := uint16(0)
	if x < 0 {
		sign, x = 0x8000, -x
	}
	if x < math.Ldexp(1, -14) { // subnormal: units of 2^-24
		mant := uint32(math.RoundToEven(math.Ldexp(x, 24)))
		return sign | uint16(mant) // 1024 rolls into the smallest normal
	}
	_, exp := math.Frexp(x) // x in [2^(exp-1), 2^exp)
	e := exp - 1 + 15
	if e >= 31 {
		return sign | 0x7c00
	}
	mant := uint32(math.RoundToEven((math.Ldexp(x, -(exp-1)) - 1) * 1024))
	if mant == 1024 {
		mant = 0
		e++
		if e >= 31 {
			return sign | 0x7c00
		}
	}
	return sign | uint16(e)<<10 | uint16(mant)
}

// dotFMLAL is the kernel's K.Q: two f32 accumulators of four lanes over
// eight-element chunks (FMLAL the low four, FMLAL2 the high four),
// added lanewise, then two pairwise adds.
func dotFMLAL(k, q []float64, DK int) float32 {
	var a0, a1 [4]float32
	for c := 0; c < DK/8; c++ {
		for l := 0; l < 4; l++ {
			a0[l] = fma32(float32(k[8*c+l]), float32(q[8*c+l]), a0[l])
			a1[l] = fma32(float32(k[8*c+4+l]), float32(q[8*c+4+l]), a1[l])
		}
	}
	var v [4]float32
	for l := 0; l < 4; l++ {
		v[l] = a0[l] + a1[l]
	}
	return (v[0] + v[1]) + (v[2] + v[3])
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
	// DV other than 64/128 runs the body's per-position f32 loop (the
	// NEON algorithm): the exact float64 reference.
	if DV != 64 && DV != 128 {
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
		if got := get32(mem, smOff+4); math.Abs(float64(got)-M) > 1e-5*math.Max(1, math.Abs(M)) {
			t.Fatalf("%s: M = %v, want %v", desc, got, M)
		}
		for i := 0; i < DV; i++ {
			if got := get32(mem, vkqOff+4*i); math.Abs(float64(got)-vkq[i]) > 1e-4*math.Max(1, math.Abs(vkq[i])) {
				t.Fatalf("%s: VKQ[%d] = %v, want %v", desc, i, got, vkq[i])
			}
		}
		return
	}
	// reference: the kernel's arithmetic, step for step (blocks of eight,
	// f32 FMLAL dot, its expf polynomial, f16 weights, f16 accumulation
	// with one rounding per fused multiply-add - ggml's native NEON path
	// keeps the same f16 accumulator).
	S32, M32 := float32(S), float32(M)
	vkq16 := make([]uint16, DV)
	for i := range vkq {
		vkq16[i] = f16bits(float32(vkq[i]))
	}
	for p0 := start; p0 < n; p0 += 8 {
		nb := n - p0
		if nb > 8 {
			nb = 8
		}
		sv := make([]float32, 8)
		mb := float32(math.Inf(-1))
		for j := 0; j < 8; j++ {
			sv[j] = float32(math.Inf(-1))
			if j >= nb {
				continue
			}
			p := p0 + j
			mv := float32(0)
			if withMask {
				mv = slope * float32(mask[p])
			}
			sv[j] = fma32(dotFMLAL(k[p], q, DK), scale, mv)
			if sv[j] > mb {
				mb = sv[j]
			}
		}
		if math.IsInf(float64(mb), -1) {
			continue
		}
		if mb > M32 {
			if !math.IsInf(float64(M32), -1) {
				ms := expf32(M32 - mb)
				S32 *= ms
				ms16 := f16val(f16of(float64(ms)))
				for i := range vkq16 {
					vkq16[i] = f16of(f16val(vkq16[i]) * ms16)
				}
			}
			M32 = mb
		}
		var pw [8]float32
		for j := 0; j < 8; j++ {
			x := sv[j] - M32
			if x < -200 {
				x = -200
			}
			pw[j] = expf32(x)
		}
		var sum [4]float32
		for l := 0; l < 4; l++ {
			sum[l] = pw[l] + pw[4+l]
		}
		S32 += (sum[0] + sum[1]) + (sum[2] + sum[3])
		for j := 0; j < nb; j++ {
			p16 := f16val(f16of(float64(pw[j])))
			for i := range vkq16 {
				vkq16[i] = f16of(f16val(vkq16[i]) + p16*v[p0+j][i])
			}
		}
	}
	S, M = float64(S32), float64(M32)
	for i := range vkq {
		vkq[i] = f16val(vkq16[i])
	}
	desc := "DK=" + itoa(DK) + " DV=" + itoa(DV) + " n=" + itoa(n) + " start=" + itoa(start)
	if got := get32(mem, smOff); !close64(got, S, 1e-6) {
		t.Fatalf("%s: S = %v, want %v", desc, got, S)
	}
	// M is one f32 score (an f32 dot of DK terms, fused with the scale):
	// a few ulps of the score magnitude.
	if got := get32(mem, smOff+4); math.Abs(float64(got)-M) > 1e-6*math.Max(1e-3, math.Abs(M)) {
		t.Fatalf("%s: M = %v, want %v", desc, got, M)
	}
	// VKQ sums n terms of magnitude up to vs*|v| <= 1 in f32 (the wasm
	// body does the same), so the bar is set against that magnitude,
	// not the (possibly cancelled) result.
	// VKQ is the f16 accumulator widened: exact up to the reference's
	// own rounding emulation (one f16 ulp of slack).
	for i := 0; i < DV; i++ {
		got := get32(mem, vkqOff+4*i)
		ulp := math.Ldexp(1, -10) * math.Max(math.Ldexp(1, -14), math.Abs(vkq[i]))
		if math.Abs(float64(got)-vkq[i]) > ulp {
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

const flashAttnFHMRunTest = `package attnrun

import "testing"

func TestFlashAttn(t *testing.T) {
	seed := uint32(17)
	for _, d := range [][2]int{{64, 64}, {128, 128}, {64, 128}, {16, 64}, {8, 8}, {24, 40}, {72, 8}} {
		for _, n := range []int{1, 2, 5, 8, 9, 64, 301} {
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
	runAttn(t, AttnKernel, 64, 64, 4, 4, 0, false, true, 99)
}
`

func TestA64FlashAttnFHMKernelGate(t *testing.T) {
	_, argBytes := flashAttnArgs(true)
	pool := NewConstPool("fh_")
	body := a64FlashAttnFHMKernel("AttnKernel", pool, true) + "\n" + pool.Emit()
	asm := wrap("arm64", "AttnKernel", faFHMFrame, argBytes, "fhm", body)
	dir := t.TempDir()
	writeRunTree(t, dir, "attnrun", "arm64", asm, flashAttnFHMRunSrc+flashAttnDecls, flashAttnFHMRunTest)
	runArm64Gate(t, dir, ".", "TestFlashAttn", asm)
}
