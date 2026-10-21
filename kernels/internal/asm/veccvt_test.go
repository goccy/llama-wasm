package asm

import (
	"strings"
	"testing"
)

func TestVecCvtKernelsEmit(t *testing.T) {
	pool := &ConstPool{}
	if s := a64VecCvtF32ToF16Kernel("Fn22neon", pool, true); !strings.Contains(s, "fcvtn2") || !strings.Contains(s, "fcvt h0, s0") {
		t.Fatalf("a64 f32->f16 body:\n%s", s)
	}
	if s := a64VecCvtF16ToF32Kernel("Fn23neon", pool, true); !strings.Contains(s, "fcvtl2") || !strings.Contains(s, "ldr h0") {
		t.Fatalf("a64 f16->f32 body:\n%s", s)
	}
	if s := x64VecCvtF32ToF16Kernel("Fn22avx2", pool, true); !strings.Contains(s, "VCVTPS2PH") {
		t.Fatalf("x64 f32->f16 body:\n%s", s)
	}
	if s := x64VecCvtF16ToF32Kernel("Fn23avx2", pool, true); !strings.Contains(s, "VCVTPH2PS") {
		t.Fatalf("x64 f16->f32 body:\n%s", s)
	}
}

const vecCvtRunSrc = `package cvtrun

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

func putU16(mem []byte, off int, v uint16) { mem[off], mem[off+1] = byte(v), byte(v>>8) }
func getU16(mem []byte, off int) uint16   { return uint16(mem[off]) | uint16(mem[off+1])<<8 }

// f16bits rounds f to the nearest half (ties to even), the IEEE
// conversion with subnormals and overflow to infinity.
func f16bits(f float32) uint16 {
	b := math.Float32bits(f)
	sign := uint16(b>>16) & 0x8000
	exp := int((b>>23)&0xff) - 127
	mant := b & 0x7fffff
	switch {
	case exp == 128: // inf / nan
		if mant != 0 {
			return sign | 0x7e00
		}
		return sign | 0x7c00
	case exp > 15:
		return sign | 0x7c00
	case exp >= -14:
		m := (uint32(exp+15) << 10) | mant>>13
		rem := mant & 0x1fff
		if rem > 0x1000 || (rem == 0x1000 && m&1 == 1) {
			m++
		}
		return sign | uint16(m)
	default:
		if exp < -25 {
			return sign
		}
		full := mant | 0x800000
		shift := uint(-exp - 1) // bits dropped: 14 + (-14 - exp)
		m := full >> shift
		rem := full & (1<<shift - 1)
		half := uint32(1) << (shift - 1)
		if rem > half || (rem == half && m&1 == 1) {
			m++
		}
		return sign | uint16(m)
	}
}

func f16toF32(h uint16) float32 {
	sign := uint32(h&0x8000) << 16
	exp := int((h >> 10) & 0x1f)
	mant := uint32(h & 0x3ff)
	switch {
	case exp == 0x1f:
		if mant != 0 {
			return math.Float32frombits(sign | 0x7fc00000 | mant<<13)
		}
		return math.Float32frombits(sign | 0x7f800000)
	case exp == 0:
		if mant == 0 {
			return math.Float32frombits(sign)
		}
		f := float32(mant) * float32(math.Ldexp(1, -24))
		return math.Float32frombits(sign | math.Float32bits(f))
	}
	return math.Float32frombits(sign | uint32(exp+112)<<23 | mant<<13)
}

// cvtInputs mixes ordinary magnitudes with half subnormals, exact
// halves, rounding ties, overflow and zeros; no NaNs.
func cvtInputs(n int, seed uint32) []float32 {
	rng := seed
	out := make([]float32, n)
	for i := range out {
		rng = rng*1664525 + 1013904223
		switch i % 9 {
		case 0:
			out[i] = 0
		case 1:
			out[i] = -float32(math.Ldexp(1, -20)) * float32(1+rng>>29) // half subnormal
		case 2:
			out[i] = float32(math.Ldexp(1, -15)) + float32(math.Ldexp(1, -26))*float32(rng>>28)
		case 3:
			out[i] = 70000 * float32(1+rng>>30) // overflows to inf
		case 4:
			out[i] = math.Float32frombits((rng & 0x7fff) << 13) // exact halves and ties
		default:
			out[i] = float32(int32(rng>>8)%2000001-1000000) / 977
		}
	}
	return out
}

func runCvtF32ToF16(t *testing.T, kernel func(m *mockModule, l0, l1, l2 int64), n int) {
	t.Helper()
	x := cvtInputs(n, uint32(n)*131+7)
	mem := make([]byte, 4096+6*n*4)
	xOff := 256
	yOff := xOff + n*4 + 64
	for i, v := range x {
		putF32(mem, xOff+4*i, v)
	}
	memSize := uint64(len(mem))
	m := &mockModule{memSizePtr: &memSize, mem: unsafe.Pointer(&mem[0])}
	before := append([]byte(nil), mem...)
	kernel(m, int64(xOff), int64(yOff), int64(n))
	refCheck(t, kernel, before, mem, []refArg{rPtr(int64(xOff)), rPtr(int64(yOff)), rI64(int64(n))},
		nil, []refOut{outBytes(yOff, 2 * n)}, 0)
	for i, v := range x {
		if got, want := getU16(mem, yOff+2*i), f16bits(v); got != want {
			t.Fatalf("n=%d y[%d] = %#04x, want %#04x (x=%v)", n, i, got, want, v)
		}
	}
	for off := yOff + 2*n; off < len(mem); off++ {
		if mem[off] != 0 {
			t.Fatalf("n=%d byte %d past y written", n, off)
		}
	}
}

func runCvtF16ToF32(t *testing.T, kernel func(m *mockModule, l0, l1, l2 int64), n int) {
	t.Helper()
	rng := uint32(n)*61 + 11
	x := make([]uint16, n)
	for i := range x {
		rng = rng*1664525 + 1013904223
		h := uint16(rng >> 16)
		if h&0x7c00 == 0x7c00 {
			h &= 0x83ff // no inf/nan: an exact subnormal instead
		}
		x[i] = h
	}
	mem := make([]byte, 4096+6*n*4)
	xOff := 256
	yOff := xOff + n*2 + 64
	for i, v := range x {
		putU16(mem, xOff+2*i, v)
	}
	memSize := uint64(len(mem))
	m := &mockModule{memSizePtr: &memSize, mem: unsafe.Pointer(&mem[0])}
	before := append([]byte(nil), mem...)
	kernel(m, int64(xOff), int64(yOff), int64(n))
	refCheck(t, kernel, before, mem, []refArg{rPtr(int64(xOff)), rPtr(int64(yOff)), rI64(int64(n))},
		nil, []refOut{outBytes(yOff, 4 * n)}, 0)
	for i, v := range x {
		if got, want := getF32(mem, yOff+4*i), f16toF32(v); math.Float32bits(got) != math.Float32bits(want) {
			t.Fatalf("n=%d y[%d] = %v, want %v (x=%#04x)", n, i, got, want, v)
		}
	}
	for off := yOff + 4*n; off < len(mem); off++ {
		if mem[off] != 0 {
			t.Fatalf("n=%d byte %d past y written", n, off)
		}
	}
}
`

const vecCvtDecls = "\nfunc CvtF32ToF16Kernel(m *mockModule, l0, l1, l2 int64)\nfunc CvtF16ToF32Kernel(m *mockModule, l0, l1, l2 int64)\n"

const vecCvtRunTest = `package cvtrun

import "testing"

func TestVecCvt(t *testing.T) {
	for _, n := range []int{64, 1, 3, 4, 7, 8, 9, 15, 16, 17, 768, 4864} {
		runCvtF32ToF16(t, CvtF32ToF16Kernel, n)
		runCvtF16ToF32(t, CvtF16ToF32Kernel, n)
	}
}
`

func TestA64VecCvtKernelGate(t *testing.T) {
	_, argBytes := vecCvtArgs(true)
	pool := &ConstPool{}
	asm := wrap("arm64", "CvtF32ToF16Kernel", 16, argBytes, "neon", a64VecCvtF32ToF16Kernel("CvtF32ToF16Kernel", pool, true)) +
		wrap("arm64", "CvtF16ToF32Kernel", 16, argBytes, "neon", a64VecCvtF16ToF32Kernel("CvtF16ToF32Kernel", pool, true)) + pool.Emit()
	dir := t.TempDir()
	writeRunTree(t, dir, "cvtrun", "arm64", asm, vecCvtRunSrc+vecCvtDecls, vecCvtRunTest, "CvtF32ToF16Kernel", "dbg_cpu_fp32_to_fp16", "CvtF16ToF32Kernel", "dbg_cpu_fp16_to_fp32")
	runArm64Gate(t, dir, ".", "TestVecCvt", asm)
}

func TestX64VecCvtKernelGate(t *testing.T) {
	_, argBytes := vecCvtArgs(true)
	pool := &ConstPool{}
	asm := wrap("amd64", "CvtF32ToF16Kernel", 16, argBytes, "avx2", x64VecCvtF32ToF16Kernel("CvtF32ToF16Kernel", pool, true)) +
		wrap("amd64", "CvtF16ToF32Kernel", 16, argBytes, "avx2", x64VecCvtF16ToF32Kernel("CvtF16ToF32Kernel", pool, true)) + pool.Emit()
	dir := t.TempDir()
	writeRunTree(t, dir, "cvtrun", "amd64", asm, vecCvtRunSrc+vecCvtDecls, vecCvtRunTest, "CvtF32ToF16Kernel", "dbg_cpu_fp32_to_fp16", "CvtF16ToF32Kernel", "dbg_cpu_fp16_to_fp32")
	runAmd64Gate(t, dir, ".", "TestVecCvt", asm)
}
