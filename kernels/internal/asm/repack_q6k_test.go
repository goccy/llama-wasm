package asm

import (
	"strings"
	"testing"
)

func TestGemvQ6K8x8KernelShape(t *testing.T) {
	a := a64GemvQ6K8x8Kernel("Fn7dotprod", true)
	for _, want := range []string{"g6group:", "g6blk:", "g6store:", "ovr_oob", "sdot v8.4s", "smlal v4.4s", "addp v20.4s"} {
		if !strings.Contains(a, want) {
			t.Fatalf("q6_K gemv missing %q", want)
		}
	}
}

const q6Kx8RunSrc = `
// repackQ6Kx8 interleaves eight plain q6_K rows (nb blocks each) into
// nb block_q6_Kx8 blocks (llama.cpp make_block_q6_Kx8, interleave 8).
func repackQ6Kx8(rows [8][]byte, nb int) []byte {
	out := make([]byte, nb*1680)
	for b := 0; b < nb; b++ {
		o := out[b*1680:]
		var in [8][]byte
		for j := 0; j < 8; j++ {
			in[j] = rows[j][b*210:]
		}
		for j := 0; j < 8; j++ {
			copy(o[2*j:], in[j][208:210])
		}
		for j := 0; j < 16; j++ {
			for c := 0; c < 8; c++ {
				o[16+8*j+c] = in[c][192+j]
			}
		}
		for i := 0; i < 128; i++ {
			copy(o[144+8*i:144+8*i+8], in[i%8][(i/8)*8:(i/8)*8+8])
		}
		for i := 0; i < 64; i++ {
			copy(o[1168+8*i:1168+8*i+8], in[i%8][128+(i/8)*8:128+(i/8)*8+8])
		}
	}
	return out
}

// genQ6KRow fills nb plain q6_K blocks.
func genQ6KRow(s *lcg, nb int) []byte {
	x := make([]byte, nb*210)
	for b := 0; b < nb; b++ {
		xb := x[b*210:]
		for i := 0; i < 192; i++ {
			xb[i] = s.byte_()
		}
		for i := 0; i < 16; i++ {
			xb[192+i] = byte(s.i8())
		}
		put16(xb, 208, f16bits(s.scale()/64))
	}
	return x
}

// dotQ6KRow: float64 dot of a plain q6_K row against dequantized
// activations, and the sum of the per-block magnitudes.
func dotQ6KRow(x []byte, yv []float64, nb int) (float64, float64) {
	var want, mag float64
	for b := 0; b < nb; b++ {
		xb := x[b*210:]
		d := f16val(uint16(xb[208]) | uint16(xb[209])<<8)
		var blk float64
		for h := 0; h < 2; h++ {
			for l := 0; l < 32; l++ {
				ql0 := int(xb[64*h+l])
				ql1 := int(xb[64*h+32+l])
				qh := int(xb[128+32*h+l])
				q := [4]int{
					(ql0 & 0xf) | ((qh >> 0) & 3) << 4,
					(ql1 & 0xf) | ((qh >> 2) & 3) << 4,
					(ql0 >> 4) | ((qh >> 4) & 3) << 4,
					(ql1 >> 4) | ((qh >> 6) & 3) << 4,
				}
				for k := 0; k < 4; k++ {
					pos := 128*h + 32*k + l
					sc := float64(int8(xb[192+pos/16]))
					blk += d * sc * float64(q[k]-32) * yv[b*256+pos]
				}
			}
		}
		want += blk
		mag += math.Abs(blk)
	}
	return want, mag
}

// runGemvQ6K: nc/8 column groups of repacked weights against one q8_K
// row; s[c] must match the plain dot of row c.
func runGemvQ6K(t *testing.T, kernel gemvKernel, n, nc int, seed uint32) {
	t.Helper()
	nb := n / 256
	s := lcg(seed)
	y, yv := genQ8_K(&s, nb)
	var rows [][]byte
	var vx []byte
	for g := 0; g < nc/8; g++ {
		var eight [8][]byte
		for j := 0; j < 8; j++ {
			eight[j] = genQ6KRow(&s, nb)
			rows = append(rows, eight[j])
		}
		vx = append(vx, repackQ6Kx8(eight, nb)...)
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
		want, mag := dotQ6KRow(rows[c], yv, nb)
		if got := get32(mem, sOff+4*c); !closeMag(got, want, mag) {
			t.Fatalf("gemv q6_K n=%d nc=%d col %d = %v, want %v", n, nc, c, got, want)
		}
	}
	for off := sOff + 4*nc; off < xOff; off++ {
		if mem[off] != 0 {
			t.Fatalf("gemv q6_K n=%d nc=%d: byte %d past s written", n, nc, off)
		}
	}
}

// runGemmQ6K: nr/4 groups of four activation rows against nc/8 column
// groups; s[row*bs + col] must match the plain dots.
func runGemmQ6K(t *testing.T, kernel gemmKernel, n, nr, nc int, seed uint32) {
	t.Helper()
	nb := n / 256
	s := lcg(seed)
	var rows [][]byte
	var vx []byte
	for g := 0; g < nc/8; g++ {
		var eight [8][]byte
		for j := 0; j < 8; j++ {
			eight[j] = genQ6KRow(&s, nb)
			rows = append(rows, eight[j])
		}
		vx = append(vx, repackQ6Kx8(eight, nb)...)
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
	bs := nc + 8
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
			want, mag := dotQ6KRow(rows[c], yvs[r], nb)
			if got := get32(mem, sOff+4*(r*bs+c)); !closeMag(got, want, mag) {
				t.Fatalf("gemm q6_K n=%d nr=%d nc=%d [%d][%d] = %v, want %v", n, nr, nc, r, c, got, want)
			}
		}
		for c := nc; c < bs; c++ {
			if get32(mem, sOff+4*(r*bs+c)) != 0 {
				t.Fatalf("gemm q6_K n=%d nr=%d nc=%d: slack [%d][%d] written", n, nr, nc, r, c)
			}
		}
	}
}
`

const q6Kx8Decls = "\nfunc GemvKernel(m *mockModule, l0 int32, l1, l2, l3, l4 int64, l5, l6 int32)\nfunc GemmKernel(m *mockModule, l0 int32, l1, l2, l3, l4 int64, l5, l6 int32)\nfunc trapstub()\n\nvar _ = trapstub\n"

const q6Kx8RunTest = `package quantrun

import "testing"

func TestGemvQ6K(t *testing.T) {
	seed := uint32(5)
	for _, n := range []int{256, 512, 1536} {
		for _, nc := range []int{8, 16, 24} {
			seed++
			runGemvQ6K(t, GemvKernel, n, nc, seed)
		}
	}
}

func TestGemmQ6K(t *testing.T) {
	seed := uint32(60)
	for _, n := range []int{256, 512, 1536} {
		for _, nr := range []int{4, 8} {
			for _, nc := range []int{8, 16, 24} {
				seed++
				runGemmQ6K(t, GemmKernel, n, nr, nc, seed)
			}
		}
	}
}
`

func TestGemmQ6K8x8KernelShape(t *testing.T) {
	a := a64GemmQ6K8x8Kernel("Fn7i8mm", true)
	for _, want := range []string{"m6rows:", "m6cols:", "m6blk:", "m6store:", "ovr_oob", "smmla v8.4s", "q6kscratch"} {
		if !strings.Contains(a, want) {
			t.Fatalf("q6_K gemm missing %q", want)
		}
	}
}

func TestA64Q6K8x8KernelGate(t *testing.T) {
	_, argBytes := repackGemmArgs(true)
	asm := wrap("arm64", "GemvKernel", 16, argBytes, "dotprod", a64GemvQ6K8x8Kernel("GemvKernel", true)) +
		wrap("arm64", "GemmKernel", a64GemmQ6KFrame, argBytes, "i8mm", a64GemmQ6K8x8Kernel("GemmKernel", true))
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "arm64", asm, quantRunCommon+kQuantRunSrc+q4Kx8RunSrc+q6Kx8RunSrc+q6Kx8Decls, q6Kx8RunTest)
	runArm64Gate(t, dir, ".", "TestGem[vm]Q6K", asm)
}

func TestX64Q6K8x8KernelShape(t *testing.T) {
	pool := NewConstPool("q6_")
	a := x64GemvQ6K8x8Kernel("Fn7avx2", pool, true)
	for _, want := range []string{"g6group:", "g6blk:", "VPMADDUBSW", "VPHADDD", "VPMOVSXBD", "ovr_oob"} {
		if !strings.Contains(a, want) {
			t.Fatalf("x64 q6_K gemv missing %q", want)
		}
	}
	g := x64GemmQ6K8x8Kernel("Fn8avx2", NewConstPool("q6m_"), true)
	for _, want := range []string{"m6rows:", "m6cols:", "m6blk:", "VPMADDUBSW", "VPSLLD\t$5", "ovr_oob"} {
		if !strings.Contains(g, want) {
			t.Fatalf("x64 q6_K gemm missing %q", want)
		}
	}
}

func TestX64Q6K8x8KernelGate(t *testing.T) {
	_, argBytes := repackGemmArgs(true)
	var asm string
	for _, k := range []struct {
		sym   string
		frame int
		gen   func(string, *ConstPool, bool) string
	}{{"GemvKernel", x64Q6KFrame, x64GemvQ6K8x8Kernel}, {"GemmKernel", x64Q6KTileFrame, x64GemmQ6K8x8Kernel}} {
		pool := NewConstPool("q6" + k.sym[:4] + "_")
		asm += wrap("amd64", k.sym, k.frame, argBytes, "avx2", k.gen(k.sym, pool, true)+"\n"+pool.Emit())
	}
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "amd64", asm, quantRunCommon+kQuantRunSrc+q4Kx8RunSrc+q6Kx8RunSrc+q6Kx8Decls, q6Kx8RunTest)
	runAmd64Gate(t, dir, ".", "TestGem[vm]Q6K", asm)
}
