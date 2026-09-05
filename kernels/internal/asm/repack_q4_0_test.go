package asm

import (
	"strings"
	"testing"
)

func TestQ4_0_8x8KernelShape(t *testing.T) {
	pool := NewConstPool("t_")
	a := a64GemvQ4_0_8x8Kernel("FnGvdotprod", pool, true)
	for _, want := range []string{"gv4group:", "gv4blk:", "shl v22.4s, v22.4s, #3", "ldur q8, [x9, #16]", "eor v8.16b, v8.16b, v24.16b", "ovr_oob"} {
		if !strings.Contains(a, want) {
			t.Errorf("a64 q4_0 gemv missing %q", want)
		}
	}
	if strings.Contains(a, "tbl v") {
		t.Errorf("a64 q4_0 gemv still unpacks fifth bits")
	}
	g := a64GemmQ4_0_8x8Kernel("FnGmi8mm", pool, true)
	for _, want := range []string{"gm4rows:", "gm4cols:", "gm4blk:", "q4scratch", "shl v20.4s, v20.4s, #3", "smmla v0.4s"} {
		if !strings.Contains(g, want) {
			t.Errorf("a64 q4_0 gemm missing %q", want)
		}
	}
	x := x64GemvQ4_0_8x8Kernel("FnGvavx2", NewConstPool("t_"), true)
	for _, want := range []string{"group4:", "blk4:", "VPSLLD\t$3, X10, X10", "VMOVDQU\t16(R9), Y4", "VPXOR", "VPMADDUBSW"} {
		if !strings.Contains(x, want) {
			t.Errorf("x64 q4_0 gemv missing %q", want)
		}
	}
	xm := x64GemmQ4_0_8x8Kernel("FnGmavx2", NewConstPool("t_"), true)
	for _, want := range []string{"rows4:", "cols4:", "blk4:", "VPSLLD\t$3, Y8, Y8"} {
		if !strings.Contains(xm, want) {
			t.Errorf("x64 q4_0 gemm missing %q", want)
		}
	}
}

// q4x8RunSrc: Q4_0 rows, their q4_0x8 repack (llama.cpp's block<4, 8>)
// and the GEMV/GEMM runners; q8 rows, packing, dotRows and closeQ5 come
// from q5x8RunSrc.
const q4x8RunSrc = `
// genQ4Row: nb random q4_0 blocks (18 bytes each) and their values.
func genQ4Row(s *lcg, nb int) ([]byte, []float64) {
	x := make([]byte, 18*nb)
	v := make([]float64, 32*nb)
	for b := 0; b < nb; b++ {
		d := s.scale()
		put16(x, 18*b, f16bits(d))
		dv := f16val(f16bits(d))
		for j := 0; j < 16; j++ {
			q0 := int(s.next() % 16)
			q1 := int(s.next() % 16)
			x[18*b+2+j] = byte(q0) | byte(q1)<<4
			v[32*b+j] = float64(q0-8) * dv
			v[32*b+j+16] = float64(q1-8) * dv
		}
	}
	return x, v
}

// repackX8Plain: eight 18-byte rows (q4_0 or iq4_nl) into block<4, 8>
// blocks (144 bytes): d[8] then the rows' qs bytes interleaved in 8-byte
// groups.
func repackX8Plain(rows [8][]byte, nb int) []byte {
	out := make([]byte, 144*nb)
	for b := 0; b < nb; b++ {
		o := out[144*b:]
		for c := 0; c < 8; c++ {
			copy(o[2*c:2*c+2], rows[c][18*b:18*b+2])
		}
		for i := 0; i < 16; i++ {
			copy(o[16+8*i:16+8*i+8], rows[i%8][18*b+2+(i/8)*8:18*b+2+(i/8)*8+8])
		}
	}
	return out
}

// repackQ4_0x8: llama.cpp's make_block_q4_0x8 — the plain interleave with
// every nibble xor 8 (0x88 per byte), the signed-nibble form its AVX2 path
// sign-extends.
func repackQ4_0x8(rows [8][]byte, nb int) []byte {
	out := repackX8Plain(rows, nb)
	for b := 0; b < nb; b++ {
		for i := 16; i < 144; i++ {
			out[144*b+i] ^= 0x88
		}
	}
	return out
}

func runGemvQ4(t *testing.T, kernel q5Kernel, n, nc int, seed uint32) {
	t.Helper()
	nb := n / 32
	s := lcg(seed)
	y, yv := genQ8Row(&s, nb)
	var rows [][]float64
	var vx []byte
	for g := 0; g < nc/8; g++ {
		var eight [8][]byte
		for j := 0; j < 8; j++ {
			x, xv := genQ4Row(&s, nb)
			eight[j] = x
			rows = append(rows, xv)
		}
		vx = append(vx, repackQ4_0x8(eight, nb)...)
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
		want, mag := dotRows(rows[c], yv)
		if got := get32(mem, sOff+4*c); !closeQ5(got, want, mag) {
			t.Fatalf("gemv q4_0 n=%d nc=%d col %d = %v, want %v", n, nc, c, got, want)
		}
	}
	for off := sOff + 4*nc; off < xOff; off++ {
		if mem[off] != 0 {
			t.Fatalf("gemv q4_0 n=%d nc=%d: byte %d past s written", n, nc, off)
		}
	}
}

func runGemmQ4(t *testing.T, kernel q5Kernel, n, nr, nc int, seed uint32) {
	t.Helper()
	nb := n / 32
	s := lcg(seed)
	var rows [][]float64
	var vx []byte
	for g := 0; g < nc/8; g++ {
		var eight [8][]byte
		for j := 0; j < 8; j++ {
			x, xv := genQ4Row(&s, nb)
			eight[j] = x
			rows = append(rows, xv)
		}
		vx = append(vx, repackQ4_0x8(eight, nb)...)
	}
	var yvs [][]float64
	var vy []byte
	for g := 0; g < nr/4; g++ {
		var four [4][]byte
		for r := 0; r < 4; r++ {
			y, yv := genQ8Row(&s, nb)
			four[r] = y
			yvs = append(yvs, yv)
		}
		vy = append(vy, packQ8_0x4(four, nb)...)
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
			want, mag := dotRows(rows[c], yvs[r])
			if got := get32(mem, sOff+4*(r*bs+c)); !closeQ5(got, want, mag) {
				t.Fatalf("gemm q4_0 n=%d nr=%d nc=%d [%d][%d] = %v, want %v", n, nr, nc, r, c, got, want)
			}
		}
		for c := nc; c < bs; c++ {
			if get32(mem, sOff+4*(r*bs+c)) != 0 {
				t.Fatalf("gemm q4_0 n=%d nr=%d nc=%d: slack [%d][%d] written", n, nr, nc, r, c)
			}
		}
	}
}
`

const q4x8RunTest = `package quantrun

import "testing"

func TestGemvQ4(t *testing.T) {
	seed := uint32(13)
	for _, n := range []int{32, 64, 256, 896} {
		for _, nc := range []int{8, 16, 24} {
			seed++
			runGemvQ4(t, GemvKernel, n, nc, seed)
		}
	}
}

func TestGemmQ4(t *testing.T) {
	seed := uint32(37)
	for _, n := range []int{32, 64, 256, 896} {
		for _, nr := range []int{4, 8} {
			for _, nc := range []int{8, 16, 24} {
				seed++
				runGemmQ4(t, GemmKernel, n, nr, nc, seed)
			}
		}
	}
}

func TestExactQ4(t *testing.T) {
	for _, n := range []int{32, 256, 896} {
		for _, nc := range []int{8, 24} {
			runX8Exact(t, "q4_0", GemvKernel, GemmKernel, n, nc, uint32(n+nc), genQ4Row, repackQ4_0x8)
		}
	}
}
`

func TestA64Q4_0_8x8KernelGate(t *testing.T) {
	_, argBytes := repackGemmArgs(true)
	pool := NewConstPool("q4_")
	asm := wrap("arm64", "GemvKernel", 16, argBytes, "dotprod", a64GemvQ4_0_8x8Kernel("GemvKernel", pool, true)) +
		wrap("arm64", "GemmKernel", a64GemmQ5Frame, argBytes, "i8mm", a64GemmQ4_0_8x8Kernel("GemmKernel", pool, true)) + pool.Emit()
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "arm64", asm, quantRunCommon+q5x8RunSrc+q4x8RunSrc+q5x8Decls, q4x8RunTest)
	runArm64Gate(t, dir, ".", "TestGem[vm]Q4|TestExactQ4", asm)
}

func TestX64Q4_0_8x8KernelGate(t *testing.T) {
	_, argBytes := repackGemmArgs(true)
	pool := NewConstPool("q4x_")
	asm := wrap("amd64", "GemvKernel", 16, argBytes, "avx2", x64GemvQ4_0_8x8Kernel("GemvKernel", pool, true)) +
		wrap("amd64", "GemmKernel", x64GemmQ5Frame, argBytes, "avx2", x64GemmQ4_0_8x8Kernel("GemmKernel", pool, true)) + pool.Emit()
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "amd64", asm, quantRunCommon+q5x8RunSrc+q4x8RunSrc+q5x8Decls, q4x8RunTest)
	runAmd64Gate(t, dir, ".", "TestGem[vm]Q4|TestExactQ4", asm)
}
