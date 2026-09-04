package asm

import (
	"strings"
	"testing"
)

func TestGemmQ4K8x8KernelShape(t *testing.T) {
	a := a64GemmQ4K8x8Kernel("Fn8i8mm", true)
	for _, want := range []string{"smmla v8.4s, v16.16b, v18.16b", "smmla v11.4s, v17.16b, v19.16b", "mla v7.4s, v11.4s, v21.4s", "uzp2 v12.4s, v6.4s, v7.4s", "smlal2 v23.4s, v24.8h, v11.h[7]", "q4kscratch-256(SP), R23", "gmrows:", "gmcols:", "stur q24, [x23, #240]"} {
		if !strings.Contains(a, want) {
			t.Errorf("a64 q4_K 8x8 gemm missing %q", want)
		}
	}
}

func TestGemvQ4K8x8KernelShape(t *testing.T) {
	a := a64GemvQ4K8x8Kernel("Fn7dotprod", true)
	for _, want := range []string{"sdot v8.4s, v25.16b, v16.16b", "sdot v11.4s, v26.16b, v23.16b", "addp v14.4s, v8.4s, v9.4s", "smlal2 v7.4s, v5.8h, v6.h[7]", "fmls v1.4s, v7.4s, v29.4s", "ADD\t$896, R9, R12", "gkgroup:", "l6+52(FP)"} {
		if !strings.Contains(a, want) {
			t.Errorf("a64 q4_K 8x8 gemv missing %q", want)
		}
	}
}

// q4Kx8RunSrc: plain q4_K rows repacked into block_q4_Kx8 the way
// llama.cpp's make_block_q4_Kx8 does, dotted against plain q8_K
// activations by the kernel and by the per-row float64 reference.
const q4Kx8RunSrc = `
// repackQ4Kx8 interleaves eight plain q4_K rows (nb blocks each) into
// nb block_q4_Kx8 blocks (llama.cpp make_block_q4_Kx8, interleave 8).
func repackQ4Kx8(rows [8][]byte, nb int) []byte {
	out := make([]byte, nb*1152)
	for b := 0; b < nb; b++ {
		o := out[b*1152:]
		var in [8][]byte
		for j := 0; j < 8; j++ {
			in[j] = rows[j][b*144:]
		}
		for j := 0; j < 8; j++ {
			copy(o[2*j:], in[j][0:2])
			copy(o[16+2*j:], in[j][2:4])
		}
		for i := 0; i < 128; i++ {
			src := i % 8
			copy(o[128+i*8:128+i*8+8], in[src][16+(i/8)*8:16+(i/8)*8+8])
		}
		var s, m [8]byte
		for i := 0; i < 4; i++ {
			for j := 0; j < 8; j++ {
				s[j] = in[j][4+i] & 63
				m[j] = in[j][4+i+4] & 63
			}
			for j := 0; j < 4; j++ {
				o[32+i*12+j] = (s[j] & 63) + ((s[4+j] & 48) << 2)
				o[32+i*12+4+j] = (m[j] & 63) + ((m[4+j] & 48) << 2)
				o[32+i*12+8+j] = (s[4+j] & 15) + ((m[4+j] & 15) << 4)
			}
		}
		for i := 0; i < 4; i++ {
			for j := 0; j < 8; j++ {
				s[j] = ((in[j][4+i] & 192) >> 2) | (in[j][4+i+8] & 15)
				m[j] = ((in[j][4+i+4] & 192) >> 2) | ((in[j][4+i+8] & 240) >> 4)
			}
			for j := 0; j < 4; j++ {
				o[32+i*12+48+j] = (s[j] & 63) + ((s[4+j] & 48) << 2)
				o[32+i*12+52+j] = (m[j] & 63) + ((m[4+j] & 48) << 2)
				o[32+i*12+56+j] = (s[4+j] & 15) + ((m[4+j] & 15) << 4)
			}
		}
	}
	return out
}

// genQ4KRow fills nb plain q4_K blocks.
func genQ4KRow(s *lcg, nb int) []byte {
	x := make([]byte, nb*144)
	for b := 0; b < nb; b++ {
		xb := x[b*144:]
		put16(xb, 0, f16bits(s.scale()/4))
		put16(xb, 2, f16bits(s.scale()/64))
		for i := 0; i < 12; i++ {
			xb[4+i] = s.byte_()
		}
		for i := 0; i < 128; i++ {
			xb[16+i] = s.byte_()
		}
	}
	return x
}

// dotQ4KRow: float64 dot of a plain q4_K row against dequantized
// activations, and the sum of the per-block magnitudes (the f32
// kernels accumulate block by block, so their rounding scales with
// that, not with a cancelled result).
func dotQ4KRow(x []byte, yv []float64, nb int) (float64, float64) {
	var want, mag float64
	for b := 0; b < nb; b++ {
		xb := x[b*144:]
		d := f16val(uint16(xb[0]) | uint16(xb[1])<<8)
		dmin := f16val(uint16(xb[2]) | uint16(xb[3])<<8)
		var blk, blkMin float64
		for j := 0; j < 8; j++ {
			sc, m := scaleMinK4(xb[4:16], j)
			for i := 0; i < 32; i++ {
				q := int(xb[16+32*(j/2)+i])
				if j%2 == 0 {
					q &= 0xf
				} else {
					q >>= 4
				}
				blk += d * float64(sc) * float64(q) * yv[b*256+32*j+i]
				blkMin += dmin * float64(m) * yv[b*256+32*j+i]
			}
		}
		want += blk - blkMin
		mag += math.Abs(blk) + math.Abs(blkMin)
	}
	return want, mag
}

func closeMag(got float32, want, mag float64) bool {
	return math.Abs(float64(got)-want) <= 2e-5*math.Max(math.Max(1, math.Abs(want)), mag)
}

type gemvKernel func(m *mockModule, l0 int32, l1, l2, l3, l4 int64, l5, l6 int32)

// packQ8Kx4 interleaves four plain q8_K rows into block_q8_Kx4 blocks
// (llama.cpp ggml_quantize_mat_q8_K_4x8's layout: 8-quant groups of the
// four rows in turn, block sums quarter-major).
func packQ8Kx4(rows [4][]byte, nb int) []byte {
	out := make([]byte, nb*1168)
	for b := 0; b < nb; b++ {
		o := out[b*1168:]
		for r := 0; r < 4; r++ {
			copy(o[4*r:4*r+4], rows[r][b*292:b*292+4])
		}
		for j := 0; j < 1024; j++ {
			src := (j % 32) / 8
			off := (j/32)*8 + j%8
			o[16+j] = rows[src][b*292+4+off]
		}
		var sums [64]int
		for j := 0; j < 1024; j++ {
			idx := ((j&31)>>3)<<2 + (j>>8)<<4 + (j>>6)&3
			sums[idx] += int(int8(o[16+j]))
		}
		for i := 0; i < 64; i++ {
			put16(o, 1040+2*i, uint16(int16(sums[i])))
		}
	}
	return out
}

type gemmKernel func(m *mockModule, l0 int32, l1, l2, l3, l4 int64, l5, l6 int32)

// runGemmQ4K: nr/4 groups of four activation rows against nc/8 column
// groups; s[row*bs + col] must match the plain dots.
func runGemmQ4K(t *testing.T, kernel gemmKernel, n, nr, nc int, seed uint32) {
	t.Helper()
	nb := n / 256
	s := lcg(seed)
	var rows [][]byte
	var vx []byte
	for g := 0; g < nc/8; g++ {
		var eight [8][]byte
		for j := 0; j < 8; j++ {
			eight[j] = genQ4KRow(&s, nb)
			rows = append(rows, eight[j])
		}
		vx = append(vx, repackQ4Kx8(eight, nb)...)
	}
	var yvs [][]float64
	var vy []byte
	for g := 0; g < nr/4; g++ {
		var four [4][]byte
		for r := 0; r < 4; r++ {
			y, yv := genQ8_K(&s, nb)
			four[r] = y
			yvs = append(yvs, yv)
		}
		vy = append(vy, packQ8Kx4(four, nb)...)
	}
	bs := nc + 8 // output row stride in floats, with slack past each row
	sOff, xOff := 256, 256+nr*bs*4+64
	yOff := xOff + len(vx) + 64
	mem := make([]byte, yOff+len(vy)+256)
	copy(mem[xOff:], vx)
	copy(mem[yOff:], vy)
	memSize := uint64(len(mem))
	m := &mockModule{memSizePtr: &memSize, mem: unsafe.Pointer(&mem[0])}
	kernel(m, int32(n), int64(sOff), int64(bs), int64(xOff), int64(yOff), int32(nr), int32(nc))
	for r := 0; r < nr; r++ {
		for c := 0; c < nc; c++ {
			want, mag := dotQ4KRow(rows[c], yvs[r], nb)
			if got := get32(mem, sOff+4*(r*bs+c)); !closeMag(got, want, mag) {
				t.Fatalf("gemm q4_K n=%d nr=%d nc=%d [%d][%d] = %v, want %v", n, nr, nc, r, c, got, want)
			}
		}
		for c := nc; c < bs; c++ {
			if get32(mem, sOff+4*(r*bs+c)) != 0 {
				t.Fatalf("gemm q4_K n=%d nr=%d nc=%d: slack [%d][%d] written", n, nr, nc, r, c)
			}
		}
	}
}

// runGemvQ4K: nc/8 column groups of repacked weights against one q8_K
// row; s[c] must match the plain dot of row c.
func runGemvQ4K(t *testing.T, kernel gemvKernel, n, nc int, seed uint32) {
	t.Helper()
	nb := n / 256
	s := lcg(seed)
	y, yv := genQ8_K(&s, nb)
	var rows [][]byte
	var vx []byte
	for g := 0; g < nc/8; g++ {
		var eight [8][]byte
		for j := 0; j < 8; j++ {
			eight[j] = genQ4KRow(&s, nb)
			rows = append(rows, eight[j])
		}
		vx = append(vx, repackQ4Kx8(eight, nb)...)
	}
	sOff, xOff := 256, 1024
	yOff := xOff + len(vx) + 64
	mem := make([]byte, yOff+len(y)+256)
	copy(mem[xOff:], vx)
	copy(mem[yOff:], y)
	memSize := uint64(len(mem))
	m := &mockModule{memSizePtr: &memSize, mem: unsafe.Pointer(&mem[0])}
	kernel(m, int32(n), int64(sOff), int64(nc), int64(xOff), int64(yOff), 1, int32(nc))
	for c := 0; c < nc; c++ {
		want, mag := dotQ4KRow(rows[c], yv, nb)
		if got := get32(mem, sOff+4*c); !closeMag(got, want, mag) {
			t.Fatalf("gemv q4_K n=%d nc=%d col %d = %v, want %v", n, nc, c, got, want)
		}
	}
	for off := sOff + 4*nc; off < xOff; off++ {
		if mem[off] != 0 {
			t.Fatalf("gemv q4_K n=%d nc=%d: byte %d past s written", n, nc, off)
		}
	}
}
`

const q4Kx8Decls = "\nfunc GemvKernel(m *mockModule, l0 int32, l1, l2, l3, l4 int64, l5, l6 int32)\nfunc GemmKernel(m *mockModule, l0 int32, l1, l2, l3, l4 int64, l5, l6 int32)\nfunc trapstub()\n\nvar _ = trapstub\n"

const q4Kx8RunTest = `package quantrun

import "testing"

func TestGemvQ4K(t *testing.T) {
	seed := uint32(3)
	for _, n := range []int{256, 512, 1536} {
		for _, nc := range []int{8, 16, 24} {
			seed++
			runGemvQ4K(t, GemvKernel, n, nc, seed)
		}
	}
}

func TestGemmQ4K(t *testing.T) {
	seed := uint32(40)
	for _, n := range []int{256, 512, 1536} {
		for _, nr := range []int{4, 8} {
			for _, nc := range []int{8, 16, 24} {
				seed++
				runGemmQ4K(t, GemmKernel, n, nr, nc, seed)
			}
		}
	}
}
`

func TestA64GemvQ4K8x8KernelGate(t *testing.T) {
	_, argBytes := repackGemmArgs(true)
	asm := wrap("arm64", "GemvKernel", 16, argBytes, "dotprod", a64GemvQ4K8x8Kernel("GemvKernel", true)) +
		wrap("arm64", "GemmKernel", a64GemmQ4KFrame, argBytes, "i8mm", a64GemmQ4K8x8Kernel("GemmKernel", true))
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "arm64", asm, quantRunCommon+kQuantRunSrc+q4Kx8RunSrc+q4Kx8Decls, q4Kx8RunTest)
	runArm64Gate(t, dir, ".", "TestGem[vm]Q4K", asm)
}

func TestX64Q4K8x8KernelShape(t *testing.T) {
	pool := NewConstPool("t_")
	a := x64GemvQ4K8x8Kernel("Fn7avx2", pool, true)
	for _, want := range []string{"VPBROADCASTQ\t4(DX), Y15", "VPMADDUBSW\tY15, Y7, Y7", "VPHADDD\tY3, Y2, Y2", "VPMULLD\tY12, Y2, Y2", "VPERMPS\tY0, Y11, Y0", "VPBROADCASTD\t12(SP), Y15", "gkgroup:"} {
		if !strings.Contains(a, want) {
			t.Errorf("x64 q4_K 8x8 gemv missing %q", want)
		}
	}
	b := x64GemmQ4K8x8Kernel("Fn8avx2", pool, true)
	for _, want := range []string{"VBROADCASTSS\t12(DX), Y12", "MOVWLSX\t1070(DX), BX", "VPBROADCASTQ\t1000(DX), Y15", "gmr3blk:", "DECQ\t48(SP)"} {
		if !strings.Contains(b, want) {
			t.Errorf("x64 q4_K 8x8 gemm missing %q", want)
		}
	}
}

func TestX64Q4K8x8KernelGate(t *testing.T) {
	_, argBytes := repackGemmArgs(true)
	var asm string
	for _, k := range []struct {
		sym string
		gen func(string, *ConstPool, bool) string
	}{{"GemvKernel", x64GemvQ4K8x8Kernel}, {"GemmKernel", x64GemmQ4K8x8Kernel}} {
		pool := NewConstPool(k.sym + "_")
		asm += wrap("amd64", k.sym, x64Q4KFrame, argBytes, "avx2", k.gen(k.sym, pool, true)+"\n"+pool.Emit())
	}
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "amd64", asm, quantRunCommon+kQuantRunSrc+q4Kx8RunSrc+q4Kx8Decls, q4Kx8RunTest)
	runAmd64Gate(t, dir, ".", "TestGem[vm]Q4K", asm)
}
