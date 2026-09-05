package asm

import (
	"strings"
	"testing"
)

func TestVecDotQ5_0KernelShape(t *testing.T) {
	a := a64VecDotQ5_0Kernel("Fn5dotprod", NewConstPool("t_"), true)
	for _, want := range []string{"sdot v23.4s, v6.16b, v14.16b", "cmtst v10.16b, v10.16b, v20.16b", "tbl v13.16b, {v5.16b}, v19.16b", "q5loop2:", "q5tail:", "l5+48(FP)", "VLD1\t(R5), [V18.B16, V19.B16, V20.B16]"} {
		if !strings.Contains(a, want) {
			t.Errorf("a64 q5_0 dot missing %q", want)
		}
	}
	c := q5_0Consts()
	if c[7] != 0 || c[8] != 1 || c[16] != 2 || c[31] != 3 || c[32] != 1 || c[39] != 128 || c[47] != 128 {
		t.Errorf("q5_0 const blob %v", c)
	}
}

// quantRunCommon: the mock module, f16 helpers and a deterministic
// generator shared by the quantized dot run trees.
const quantRunCommon = `package quantrun

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
func (s *lcg) byte_() byte  { return byte(s.next() >> 24) }
func (s *lcg) i8() int8     { return int8(int32(s.next()>>24)%255 - 127) }
func (s *lcg) scale() float32 {
	return float32(int32(s.next()>>8)%200+1) / 64.0
}

func close32(got float32, want float64, tolRel float64) bool {
	d := math.Abs(float64(got) - want)
	return d <= tolRel*math.Max(1, math.Abs(want))
}

type dotKernel func(m *mockModule, l0 int32, l1, l2, l3, l4, l5, l6 int64, l7 int32)

// callDot lays s at 256, x at 512 and y after x, runs the kernel and
// returns the stored f32 result. Every byte outside those ranges must
// stay untouched.
func callDot(t *testing.T, kernel dotKernel, n int, x, y []byte) float32 {
	t.Helper()
	sOff, xOff := 256, 512
	yOff := xOff + len(x) + 64
	mem := make([]byte, yOff+len(y)+256)
	copy(mem[xOff:], x)
	copy(mem[yOff:], y)
	put32(mem, sOff, 12345)
	memSize := uint64(len(mem))
	m := &mockModule{memSizePtr: &memSize, mem: unsafe.Pointer(&mem[0])}
	kernel(m, int32(n), int64(sOff), 0, int64(xOff), 0, int64(yOff), 0, 1)
	for off := range mem {
		if off >= sOff && off < sOff+4 {
			continue
		}
		var want byte
		if off >= xOff && off < xOff+len(x) {
			want = x[off-xOff]
		} else if off >= yOff && off < yOff+len(y) {
			want = y[off-yOff]
		}
		if mem[off] != want {
			t.Fatalf("n=%d byte %d written", n, off)
		}
	}
	return get32(mem, sOff)
}

// callDot2 runs the nrc == 2 tile: x1 follows x0 (bx = len(x0)), y1
// follows y0 (by = len(y0)), bs = 16 floats; returns s[0], s[1], s[16],
// s[17].
func callDot2(t *testing.T, kernel dotKernel, n int, x0, x1, y0, y1 []byte) [4]float32 {
	t.Helper()
	sOff, xOff := 256, 512
	yOff := xOff + 2*len(x0) + 64
	mem := make([]byte, yOff+2*len(y0)+256)
	copy(mem[xOff:], x0)
	copy(mem[xOff+len(x0):], x1)
	copy(mem[yOff:], y0)
	copy(mem[yOff+len(y0):], y1)
	for _, o := range []int{0, 4, 64, 68} {
		put32(mem, sOff+o, 12345)
	}
	memSize := uint64(len(mem))
	m := &mockModule{memSizePtr: &memSize, mem: unsafe.Pointer(&mem[0])}
	kernel(m, int32(n), int64(sOff), 16, int64(xOff), int64(len(x0)), int64(yOff), int64(len(y0)), 2)
	for off := sOff + 8; off < sOff+64; off++ {
		if mem[off] != 0 {
			t.Fatalf("n=%d byte %d between the tile rows written", n, off)
		}
	}
	return [4]float32{get32(mem, sOff), get32(mem, sOff+4), get32(mem, sOff+64), get32(mem, sOff+68)}
}
`

// q5_0RunSrc: random q5_0 / q8_0 blocks against a float64 reference.
const q5_0RunSrc = `
func genQ5_0(n int, seed uint32) ([]byte, []byte, float64) {
	nb := n / 32
	s := lcg(seed)
	x := make([]byte, nb*22)
	y := make([]byte, nb*34)
	var want float64
	for b := 0; b < nb; b++ {
		xb, yb := x[b*22:], y[b*34:]
		dx, dy := f16bits(s.scale()), f16bits(s.scale())
		put16(xb, 0, dx)
		put16(yb, 0, dy)
		for i := 0; i < 4; i++ {
			xb[2+i] = s.byte_()
		}
		for i := 0; i < 16; i++ {
			xb[6+i] = s.byte_()
		}
		for i := 0; i < 32; i++ {
			yb[2+i] = byte(s.i8())
		}
		qh := uint32(xb[2]) | uint32(xb[3])<<8 | uint32(xb[4])<<16 | uint32(xb[5])<<24
		sum := 0
		for j := 0; j < 16; j++ {
			xh0 := (qh >> j & 1) << 4
			xh1 := (qh >> (j + 16) & 1) << 4
			x0 := int(uint32(xb[6+j]&0x0f)|xh0) - 16
			x1 := int(uint32(xb[6+j]>>4)|xh1) - 16
			sum += x0*int(int8(yb[2+j])) + x1*int(int8(yb[2+j+16]))
		}
		want += f16val(dx) * f16val(dy) * float64(sum)
	}
	return x, y, want
}

func runQ5_0(t *testing.T, kernel dotKernel, n int) {
	t.Helper()
	x, y, want := genQ5_0(n, uint32(n)*2654435761+11)
	if got := callDot(t, kernel, n, x, y); !close32(got, want, 1e-5) {
		t.Fatalf("q5_0 n=%d dot = %v, want %v", n, got, want)
	}
}
`

const q5_0Decls = "\nfunc Q5Kernel(m *mockModule, l0 int32, l1, l2, l3, l4, l5, l6 int64, l7 int32)\nfunc trapstub()\n\nvar _ = trapstub\n"

const q5_0RunTest = `package quantrun

import "testing"

func TestQ5_0(t *testing.T) {
	for _, n := range []int{32, 64, 96, 0, 128, 896, 4864, 4864 + 32} {
		runQ5_0(t, Q5Kernel, n)
	}
}
`

func TestA64VecDotQ5_0KernelGate(t *testing.T) {
	_, argBytes := vecDotArgs(true)
	pool := NewConstPool("q5_")
	body := a64VecDotQ5_0Kernel("Q5Kernel", pool, true) + "\n" + pool.Emit()
	asm := wrap("arm64", "Q5Kernel", 16, argBytes, "dotprod", body)
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "arm64", asm, quantRunCommon+q5_0RunSrc+q5_0Decls, q5_0RunTest)
	runArm64Gate(t, dir, ".", "TestQ5_0", asm)
}
