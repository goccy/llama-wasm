package asm

import (
	"strings"
	"testing"
)

func TestQuantizeMatQ8K4x8KernelShape(t *testing.T) {
	a := a64QuantizeMatQ8K4x8Kernel("FnQneon", true)
	for _, want := range []string{"fmaxv s0, v0.4s", "fcvtns v8.4s, v8.4s", "sqxtn v11.8b, v10.8h", "str d11, [x7, #16]", "str h13, [x7, #1040]", "str h13, [x7, #1142]", "fcsel s2, s0, s1, ge", "l2+24(FP), R3"} {
		if !strings.Contains(a, want) {
			t.Errorf("kernel missing %q", want)
		}
	}
}

// quantMatRunSrc: the C body (ggml_quantize_mat_q8_K_4x8_generic) in Go,
// bit for bit: first largest-magnitude element wins, iscale = -127/max,
// d = 1/iscale, nearest_int through the 2^23 magic add.
const quantMatRunSrc = `package quantmatrun

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

func f32(mem []byte, off int) float32 {
	return math.Float32frombits(uint32(mem[off]) | uint32(mem[off+1])<<8 | uint32(mem[off+2])<<16 | uint32(mem[off+3])<<24)
}

// nearestInt: ggml's nearest_int. The explicit conversions keep the Go
// compiler from fusing the caller's multiply into the add (an FMA would
// round differently from the C, which computes the product first).
func nearestInt(f float32) int {
	v := float32(f + 12582912.0)
	i := int32(math.Float32bits(v))
	return int((i & 0x007fffff) - 0x00400000)
}

// reference fills out (nb blocks of 1168 bytes) from x[4][k].
func reference(x [4][]float32, k int) []byte {
	nb := k / 256
	out := make([]byte, nb*1168)
	for i := 0; i < nb; i++ {
		o := out[i*1168:]
		var iscale [4]float32
		for r := 0; r < 4; r++ {
			var amax, max float32
			for j := 0; j < 256; j++ {
				v := x[r][i*256+j]
				if amax < float32(math.Abs(float64(v))) {
					amax = float32(math.Abs(float64(v)))
					max = v
				}
			}
			var d float32
			if amax != 0 {
				iscale[r] = -127.0 / max
				d = 1 / iscale[r]
			}
			put32(o, 4*r, d)
		}
		var bsums [64]int16
		for j := 0; j < 1024; j++ {
			srcOff := (j/32)*8 + j%8
			srcID := (j % 32) / 8
			index := ((j&31)>>3)<<2 + (j>>8)<<4 + (j>>6)&3
			q := nearestInt(float32(x[srcID][i*256+srcOff] * iscale[srcID]))
			o[16+j] = byte(int8(q))
			bsums[index] += int16(q)
		}
		for i := 0; i < 64; i++ {
			o[1040+2*i] = byte(uint16(bsums[i]))
			o[1041+2*i] = byte(uint16(bsums[i]) >> 8)
		}
	}
	return out
}

type quantKernel func(m *mockModule, l0, l1, l2 int64)

func runQuantMat(t *testing.T, kernel quantKernel, k int, seed uint32, zeroRow int, scale float32) {
	t.Helper()
	s := lcg(seed)
	var x [4][]float32
	xOff := 256
	mem := make([]byte, xOff+4*k*4+64+k/256*1168+256)
	for r := 0; r < 4; r++ {
		x[r] = make([]float32, k)
		for j := 0; j < k; j++ {
			if r != zeroRow {
				x[r][j] = s.unit() * scale
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
			b := i % 1168
			got32 := math.Float32frombits(uint32(mem[yOff+i&^3]) | uint32(mem[yOff+i&^3+1])<<8 | uint32(mem[yOff+i&^3+2])<<16 | uint32(mem[yOff+i&^3+3])<<24)
			want32 := math.Float32frombits(uint32(want[i&^3]) | uint32(want[i&^3+1])<<8 | uint32(want[i&^3+2])<<16 | uint32(want[i&^3+3])<<24)
			blk := i / 1168 * 1168
			t.Logf("d got %v %v %v %v", f32(mem, yOff+blk), f32(mem, yOff+blk+4), f32(mem, yOff+blk+8), f32(mem, yOff+blk+12))
			t.Logf("d want %v %v %v %v", f32(want, blk), f32(want, blk+4), f32(want, blk+8), f32(want, blk+12))
			t.Logf("qs got  %v", mem[yOff+blk+16:yOff+blk+48])
			t.Logf("qs want %v", want[blk+16:blk+48])
			t.Logf("bs got  %v", mem[yOff+blk+1040:yOff+blk+1072])
			t.Logf("bs want %v", want[blk+1040:blk+1072])
			t.Fatalf("k=%d seed=%d: block %d byte %d = %#x, want %#x (f32 got %v want %v)", k, seed, i/1168, b, mem[yOff+i], want[i], got32, want32)
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

const quantMatDecls = "\nfunc QuantKernel(m *mockModule, l0, l1, l2 int64)\nfunc trapstub()\n\nvar _ = trapstub\n"

const quantMatRunTest = `package quantmatrun

import "testing"

func TestQuantMat(t *testing.T) {
	seed := uint32(3)
	for _, k := range []int{256, 512, 1536, 2048} {
		for _, zeroRow := range []int{-1, 2} {
			for _, scale := range []float32{1, 1e-3, 3e4} {
				seed++
				runQuantMat(t, QuantKernel, k, seed, zeroRow, scale)
			}
		}
	}
}
`

func TestA64QuantizeMatQ8K4x8KernelGate(t *testing.T) {
	_, argBytes := quantMatArgs(true)
	asm := wrap("arm64", "QuantKernel", 16, argBytes, "neon", a64QuantizeMatQ8K4x8Kernel("QuantKernel", true))
	dir := t.TempDir()
	writeRunTree(t, dir, "quantmatrun", "arm64", asm, quantMatRunSrc+quantMatDecls, quantMatRunTest)
	runArm64Gate(t, dir, ".", "TestQuantMat", asm)
}

func TestX64QuantizeMatQ8K4x8KernelShape(t *testing.T) {
	a := x64QuantizeMatQ8K4x8Kernel("FnQavx2", NewConstPool("t_"), true)
	for _, want := range []string{"VCVTPS2DQ\tY8, Y8", "VPACKSSWB\tX8, X8, X8", "VMOVQ\tX8, 16(R10)", "MOVW\tAX, 1142(R10)", "VBROADCASTSS\tX7, Y7", "l2+24(FP), CX"} {
		if !strings.Contains(a, want) {
			t.Errorf("kernel missing %q", want)
		}
	}
}

func TestX64QuantizeMatQ8K4x8KernelGate(t *testing.T) {
	_, argBytes := quantMatArgs(true)
	pool := NewConstPool("qm_")
	asm := wrap("amd64", "QuantKernel", 16, argBytes, "avx2", x64QuantizeMatQ8K4x8Kernel("QuantKernel", pool, true)+"\n"+pool.Emit())
	dir := t.TempDir()
	writeRunTree(t, dir, "quantmatrun", "amd64", asm, quantMatRunSrc+quantMatDecls, quantMatRunTest)
	runAmd64Gate(t, dir, ".", "TestQuantMat", asm)
}
