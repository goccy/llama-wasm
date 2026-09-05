package asm

import (
	"strings"
	"testing"
)

func TestQ5K8x8KernelShape(t *testing.T) {
	a := a64GemvQ5K8x8Kernel("Fn7dotprod", true)
	for _, want := range []string{"gk5group:", "gk5blk:", "gk5store:", "ovr_oob", "sdot v8.4s", "shl v24.16b, v24.16b, #4", "shl v24.16b, v24.16b, #3"} {
		if !strings.Contains(a, want) {
			t.Fatalf("a64 q5_K gemv missing %q", want)
		}
	}
	g := a64GemmQ5K8x8Kernel("Fn8i8mm", true)
	for _, want := range []string{"gm5rows:", "gm5cols:", "gm5blk:", "q5kscratch", "smmla v8.4s"} {
		if !strings.Contains(g, want) {
			t.Fatalf("a64 q5_K gemm missing %q", want)
		}
	}
	x := x64GemvQ5K8x8Kernel("Fn7avx2", NewConstPool("q5v_"), true)
	for _, want := range []string{"gk5group:", "VPSLLW\t$3, Y9, Y9", "VPSLLW\t$4, Y9, Y9", "VPMADDUBSW"} {
		if !strings.Contains(x, want) {
			t.Fatalf("x64 q5_K gemv missing %q", want)
		}
	}
	xm := x64GemmQ5K8x8Kernel("Fn8avx2", NewConstPool("q5m_"), true)
	for _, want := range []string{"gm5rows:", "gt5blk:", "VPSLLW\t$3, Y9, Y9"} {
		if !strings.Contains(xm, want) {
			t.Fatalf("x64 q5_K gemm missing %q", want)
		}
	}
}

const q5Kx8RunSrc = `
// repackQ5Kx8 interleaves eight plain q5_K rows (nb blocks each) into
// nb block_q5_Kx8 blocks (llama.cpp make_block_q5_Kx8, interleave 8).
func repackQ5Kx8(rows [8][]byte, nb int) []byte {
	out := make([]byte, nb*1408)
	for b := 0; b < nb; b++ {
		o := out[b*1408:]
		var in [8][]byte
		for j := 0; j < 8; j++ {
			in[j] = rows[j][b*176:]
		}
		for j := 0; j < 8; j++ {
			copy(o[2*j:], in[j][0:2])
			copy(o[16+2*j:], in[j][2:4])
		}
		for i := 0; i < 128; i++ {
			copy(o[384+i*8:384+i*8+8], in[i%8][48+(i/8)*8:48+(i/8)*8+8])
		}
		for i := 0; i < 32; i++ {
			copy(o[128+i*8:128+i*8+8], in[i%8][16+(i/8)*8:16+(i/8)*8+8])
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

// genQ5KRow fills nb plain q5_K blocks (d, dmin, scales[12], qh[32], qs[128]).
func genQ5KRow(s *lcg, nb int) []byte {
	x := make([]byte, nb*176)
	for b := 0; b < nb; b++ {
		xb := x[b*176:]
		put16(xb, 0, f16bits(s.scale()/8))
		put16(xb, 2, f16bits(s.scale()/64))
		for i := 4; i < 176; i++ {
			xb[i] = s.byte_()
		}
	}
	return x
}

// dotQ5KRow: float64 dot of a plain q5_K row against dequantized
// activations, and the sum of the per-block magnitudes.
func dotQ5KRow(x []byte, yv []float64, nb int) (float64, float64) {
	var want, mag float64
	for b := 0; b < nb; b++ {
		xb := x[b*176:]
		d := f16val(uint16(xb[0]) | uint16(xb[1])<<8)
		dmin := f16val(uint16(xb[2]) | uint16(xb[3])<<8)
		var blk, blkMin float64
		for j := 0; j < 8; j++ {
			sc, m := scaleMinK4(xb[4:16], j)
			for i := 0; i < 32; i++ {
				q := int(xb[48+32*(j/2)+i])
				if j%2 == 0 {
					q &= 0xf
				} else {
					q >>= 4
				}
				if xb[16+i]&(1<<j) != 0 {
					q += 16
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

func runGemvQ5K(t *testing.T, kernel gemvKernel, n, nc int, seed uint32) {
	t.Helper()
	nb := n / 256
	s := lcg(seed)
	y, yv := genQ8_K(&s, nb)
	var rows [][]byte
	var vx []byte
	for g := 0; g < nc/8; g++ {
		var eight [8][]byte
		for j := 0; j < 8; j++ {
			eight[j] = genQ5KRow(&s, nb)
			rows = append(rows, eight[j])
		}
		vx = append(vx, repackQ5Kx8(eight, nb)...)
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
		want, mag := dotQ5KRow(rows[c], yv, nb)
		if got := get32(mem, sOff+4*c); !closeMag(got, want, mag) {
			t.Fatalf("gemv q5_K n=%d nc=%d col %d = %v, want %v", n, nc, c, got, want)
		}
	}
	for off := sOff + 4*nc; off < xOff; off++ {
		if mem[off] != 0 {
			t.Fatalf("gemv q5_K n=%d nc=%d: byte %d past s written", n, nc, off)
		}
	}
}

func runGemmQ5K(t *testing.T, kernel gemmKernel, n, nr, nc int, seed uint32) {
	t.Helper()
	nb := n / 256
	s := lcg(seed)
	var rows [][]byte
	var vx []byte
	for g := 0; g < nc/8; g++ {
		var eight [8][]byte
		for j := 0; j < 8; j++ {
			eight[j] = genQ5KRow(&s, nb)
			rows = append(rows, eight[j])
		}
		vx = append(vx, repackQ5Kx8(eight, nb)...)
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
			want, mag := dotQ5KRow(rows[c], yvs[r], nb)
			if got := get32(mem, sOff+4*(r*bs+c)); !closeMag(got, want, mag) {
				t.Fatalf("gemm q5_K n=%d nr=%d nc=%d [%d][%d] = %v, want %v", n, nr, nc, r, c, got, want)
			}
		}
		for c := nc; c < bs; c++ {
			if get32(mem, sOff+4*(r*bs+c)) != 0 {
				t.Fatalf("gemm q5_K n=%d nr=%d nc=%d: slack [%d][%d] written", n, nr, nc, r, c)
			}
		}
	}
}
`

const q5Kx8RunTest = `package quantrun

import "testing"

func TestGemvQ5K(t *testing.T) {
	seed := uint32(7)
	for _, n := range []int{256, 512, 1536} {
		for _, nc := range []int{8, 16, 24} {
			seed++
			runGemvQ5K(t, GemvKernel, n, nc, seed)
		}
	}
}

func TestGemmQ5K(t *testing.T) {
	seed := uint32(80)
	for _, n := range []int{256, 512, 1536} {
		for _, nr := range []int{4, 8} {
			for _, nc := range []int{8, 16, 24} {
				seed++
				runGemmQ5K(t, GemmKernel, n, nr, nc, seed)
			}
		}
	}
}
`

func TestA64Q5K8x8KernelGate(t *testing.T) {
	_, argBytes := repackGemmArgs(true)
	asm := wrap("arm64", "GemvKernel", 16, argBytes, "dotprod", a64GemvQ5K8x8Kernel("GemvKernel", true)) +
		wrap("arm64", "GemmKernel", a64GemmQ4KFrame, argBytes, "i8mm", a64GemmQ5K8x8Kernel("GemmKernel", true))
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "arm64", asm, quantRunCommon+kQuantRunSrc+q4Kx8RunSrc+q5Kx8RunSrc+q6Kx8Decls, q5Kx8RunTest)
	runArm64Gate(t, dir, ".", "TestGem[vm]Q5K", asm)
}

func TestX64Q5K8x8KernelGate(t *testing.T) {
	_, argBytes := repackGemmArgs(true)
	var asm string
	for _, k := range []struct {
		sym   string
		frame int
		gen   func(string, *ConstPool, bool) string
	}{{"GemvKernel", x64Q4KFrame, x64GemvQ5K8x8Kernel}, {"GemmKernel", x64Q4KTileFrame, x64GemmQ5K8x8Kernel}} {
		pool := NewConstPool("q5" + k.sym[:4] + "_")
		asm += wrap("amd64", k.sym, k.frame, argBytes, "avx2", k.gen(k.sym, pool, true)+"\n"+pool.Emit())
	}
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "amd64", asm, quantRunCommon+kQuantRunSrc+q4Kx8RunSrc+q5Kx8RunSrc+q6Kx8Decls, q5Kx8RunTest)
	runAmd64Gate(t, dir, ".", "TestGem[vm]Q5K", asm)
}
