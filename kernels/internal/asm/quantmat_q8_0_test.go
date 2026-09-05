package asm

import (
	"strings"
	"testing"
)

func TestQuantizeMatQ8_0_4x8KernelShape(t *testing.T) {
	a := a64QuantizeMatQ8_0_4x8Kernel("FnQ8neon", true)
	for _, want := range []string{"fcvtns v10.4s, v10.4s", "fcvt h10, s10", "str d13, [x7, #104]", "fmaxv s8, v8.4s"} {
		if !strings.Contains(a, want) {
			t.Errorf("a64 kernel missing %q", want)
		}
	}
	x := x64QuantizeMatQ8_0_4x8Kernel("FnQ8avx2", NewConstPool("t_"), true)
	for _, want := range []string{"VCVTPS2DQ\tY4, Y4", "VCVTPS2PH\t$0, X5, X5", "VMOVQ\tX4, 104(R10)", "MOVW\tAX, (R11)"} {
		if !strings.Contains(x, want) {
			t.Errorf("x64 kernel missing %q", want)
		}
	}
}

// quantMatQ8RunSrc: the C body (ggml_quantize_mat_q8_0_4x8_generic) in
// Go: d = amax/127, id = 1/d, q = round-to-nearest-even(x*id) (the
// rounding of quantize_row_q8_0 and of the native SIMD quantizers; the
// llama-wasm patch aligns the scalar body's roundf to it), d stored as
// f16 (round to nearest even).
const quantMatQ8RunSrc = `package quantmatrun

import (
	"math"
	"testing"
	"unsafe"
)

type mockModule struct {
	memSizePtr *uint64
	mem        unsafe.Pointer
}

type lcg uint32

func (s *lcg) next() uint32 { *s = *s*1664525 + 1013904223; return uint32(*s) }
func (s *lcg) unit() float32 { return float32(s.next()>>8)/float32(1<<24)*2 - 1 }

func put32(mem []byte, off int, f float32) {
	b := math.Float32bits(f)
	mem[off], mem[off+1], mem[off+2], mem[off+3] = byte(b), byte(b>>8), byte(b>>16), byte(b>>24)
}
func put64(mem []byte, off int, v uint64) {
	for i := 0; i < 8; i++ {
		mem[off+i] = byte(v >> (8 * i))
	}
}

// f16bits: f32 -> f16, round to nearest even (the C conversion).
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

func reference(x [4][]float32, k int) []byte {
	nb := k / 32
	out := make([]byte, nb*136)
	for i := 0; i < nb; i++ {
		o := out[i*136:]
		for r := 0; r < 4; r++ {
			var amax float32
			for j := 0; j < 32; j++ {
				if a := float32(math.Abs(float64(x[r][i*32+j]))); a > amax {
					amax = a
				}
			}
			d := amax / 127
			var id float32
			if d != 0 {
				id = 1 / d
			}
			h := f16bits(d)
			o[2*r], o[2*r+1] = byte(h), byte(h>>8)
			for j := 0; j < 32; j++ {
				q := math.RoundToEven(float64(float32(x[r][i*32+j] * id)))
				o[8+(j/8)*32+r*8+j%8] = byte(int8(q))
			}
		}
	}
	return out
}

type quantKernel func(m *mockModule, l0, l1, l2 int64)

func runQuantMat(t *testing.T, kernel quantKernel, k int, seed uint32, zeroRow int, scale float32, ties bool) {
	t.Helper()
	s := lcg(seed)
	var x [4][]float32
	xOff := 256
	mem := make([]byte, xOff+4*k*4+64+k/32*136+256)
	for r := 0; r < 4; r++ {
		x[r] = make([]float32, k)
		for j := 0; j < k; j++ {
			if r != zeroRow {
				x[r][j] = s.unit() * scale
				if ties {
					x[r][j] = float32(int(s.next()%253)-126) + 0.5
					if j%32 == 0 {
						x[r][j] = 127
					}
				}
			}
			put32(mem, xOff+(r*k+j)*4, x[r][j])
		}
	}
	yOff := xOff + 4*k*4 + 64
	memSize := uint64(len(mem))
	m := &mockModule{memSizePtr: &memSize, mem: unsafe.Pointer(&mem[0])}
	kernel(m, int64(xOff), int64(yOff), int64(k))
	want := reference(x, k)
	for i := range want {
		if mem[yOff+i] != want[i] {
			t.Fatalf("k=%d seed=%d: block %d byte %d = %#x, want %#x", k, seed, i/136, i%136, mem[yOff+i], want[i])
		}
	}
	for off := 0; off < len(mem); off++ {
		if off >= xOff && off < yOff || off >= yOff && off < yOff+len(want) {
			continue
		}
		if mem[off] != 0 {
			t.Fatalf("k=%d: byte %d written", k, off)
		}
	}
}
`

const quantMatQ8Decls = "\nfunc QuantKernel(m *mockModule, l0, l1, l2 int64)\nfunc trapstub()\n\nvar _ = trapstub\n"

const quantMatQ8RunTest = `package quantmatrun

import "testing"

func TestQuantMat(t *testing.T) {
	seed := uint32(5)
	for _, k := range []int{32, 64, 896, 4864} {
		for _, zeroRow := range []int{-1, 1} {
			for _, scale := range []float32{1, 1e-3, 3e4, 127} {
				seed++
				runQuantMat(t, QuantKernel, k, seed, zeroRow, scale, false)
			}
		}
		runQuantMat(t, QuantKernel, k, seed, -1, 1, true)
	}
}
`

func TestA64QuantizeMatQ8_0_4x8KernelGate(t *testing.T) {
	_, argBytes := quantMatArgs(true)
	asm := wrap("arm64", "QuantKernel", 16, argBytes, "neon", a64QuantizeMatQ8_0_4x8Kernel("QuantKernel", true))
	dir := t.TempDir()
	writeRunTree(t, dir, "quantmatrun", "arm64", asm, quantMatQ8RunSrc+quantMatQ8Decls, quantMatQ8RunTest)
	runArm64Gate(t, dir, ".", "TestQuantMat", asm)
}

func TestX64QuantizeMatQ8_0_4x8KernelGate(t *testing.T) {
	_, argBytes := quantMatArgs(true)
	pool := NewConstPool("q8m_")
	asm := wrap("amd64", "QuantKernel", 16, argBytes, "avx2", x64QuantizeMatQ8_0_4x8Kernel("QuantKernel", pool, true)+"\n"+pool.Emit())
	dir := t.TempDir()
	writeRunTree(t, dir, "quantmatrun", "amd64", asm, quantMatQ8RunSrc+quantMatQ8Decls, quantMatQ8RunTest)
	runAmd64Gate(t, dir, ".", "TestQuantMat", asm)
}
