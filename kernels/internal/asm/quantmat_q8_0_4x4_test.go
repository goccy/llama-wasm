package asm

import (
	"strings"
	"testing"
)

func TestQuantizeMatQ8_0_4x4KernelShape(t *testing.T) {
	a := a64QuantizeMatQ8_0_4x4Kernel("FnQ44neon", true)
	for _, want := range []string{"fcvtns v3.4s, v3.4s", "fcvt h10, s10", "stur q6, [x2, #120]", "sqxtn2 v6.16b, v5.8h", "dup v19.4s, v9.s[0]"} {
		if !strings.Contains(a, want) {
			t.Errorf("a64 kernel missing %q", want)
		}
	}
	x := x64QuantizeMatQ8_0_4x4Kernel("FnQ44avx2", NewConstPool("t_"), true)
	for _, want := range []string{"VCVTPS2DQ\tX3, X3", "VCVTPS2PH\t$0, X5, X5", "VMOVDQU\tX0, 120(DI)", "MOVW\tAX, 6(DI)", "VPACKSSWB\tX2, X0, X0"} {
		if !strings.Contains(x, want) {
			t.Errorf("x64 kernel missing %q", want)
		}
	}
}

// The 4-wide interleave: qs[16j + 4m + i] = row m element 4j + i.
const quantMatQ8x4RunSrc = quantMatQ8RunSrc + `
func reference4x4(x [4][]float32, k int) []byte {
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
				o[8+(j/4)*16+r*4+j%4] = byte(int8(q))
			}
		}
	}
	return out
}

func runQuantMat4x4(t *testing.T, kernel quantKernel, k int, seed uint32, zeroRow int, scale float32, ties bool) {
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
	before := append([]byte(nil), mem...)
	kernel(m, int64(xOff), int64(yOff), int64(k))
	refCheck(t, kernel, before, mem, []refArg{rPtr(int64(xOff)), rPtr(int64(yOff)), rI64(int64(k))},
		nil, []refOut{outBytes(yOff, k/32*136)}, 0)
	want := reference4x4(x, k)
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

const quantMatQ8x4RunTest = `package quantmatrun

import "testing"

func TestQuantMat4x4(t *testing.T) {
	seed := uint32(9)
	for _, k := range []int{32, 64, 896, 4864} {
		for _, zeroRow := range []int{-1, 2} {
			for _, scale := range []float32{1, 1e-3, 3e4, 127} {
				seed++
				runQuantMat4x4(t, QuantKernel, k, seed, zeroRow, scale, false)
			}
		}
		runQuantMat4x4(t, QuantKernel, k, seed, -1, 1, true)
	}
}
`

func TestA64QuantizeMatQ8_0_4x4KernelGate(t *testing.T) {
	_, argBytes := quantMatArgs(true)
	asm := wrap("arm64", "QuantKernel", 16, argBytes, "neon", a64QuantizeMatQ8_0_4x4Kernel("QuantKernel", true))
	dir := t.TempDir()
	writeRunTree(t, dir, "quantmatrun", "arm64", asm, quantMatQ8x4RunSrc+quantMatQ8Decls, quantMatQ8x4RunTest, "QuantKernel", "dbg_quantize_mat_q8_0_4x4")
	runArm64Gate(t, dir, ".", "TestQuantMat4x4", asm)
}

func TestX64QuantizeMatQ8_0_4x4KernelGate(t *testing.T) {
	_, argBytes := quantMatArgs(true)
	pool := NewConstPool("q44m_")
	asm := wrap("amd64", "QuantKernel", 16, argBytes, "avx2", x64QuantizeMatQ8_0_4x4Kernel("QuantKernel", pool, true)+"\n"+pool.Emit())
	dir := t.TempDir()
	writeRunTree(t, dir, "quantmatrun", "amd64", asm, quantMatQ8x4RunSrc+quantMatQ8Decls, quantMatQ8x4RunTest, "QuantKernel", "dbg_quantize_mat_q8_0_4x4")
	runAmd64Gate(t, dir, ".", "TestQuantMat4x4", asm)
}
