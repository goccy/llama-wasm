package asm

import (
	"strings"
	"testing"
)

func TestGemvQ5_0_8x8KernelShape(t *testing.T) {
	a := a64GemvQ5_0_8x8Kernel("FnGvdotprod", NewConstPool("t_"), true)
	for _, want := range []string{"tbl v24.16b, {v11.16b}, v28.16b", "cmtst v24.16b, v24.16b, v29.16b", "sdot v3.4s, v10.16b, v14.16b", "addp v1.4s, v2.4s, v3.4s", "sub v0.4s, v0.4s, v22.4s", "ldur q8, [x9, #160]", "ldur s11, [x9, #44]"} {
		if !strings.Contains(a, want) {
			t.Errorf("gemv kernel missing %q", want)
		}
	}
}

func TestGemmQ5_0_8x8KernelShape(t *testing.T) {
	a := a64GemmQ5_0_8x8Kernel("FnGmi8mm", NewConstPool("t_"), true)
	for _, want := range []string{"smmla v0.4s, v9.16b, v12.16b", "smmla v7.4s, v10.16b, v19.16b", "uzp2 v16.4s, v4.4s, v5.4s", "q5scratch-128(SP)", "dup v23.2d, v20.d[1]"} {
		if !strings.Contains(a, want) {
			t.Errorf("gemm kernel missing %q", want)
		}
	}
}

// q5x8RunSrc: Q5_0 rows, their q5_0x8 repack (llama-wasm's
// make_block_q5_0x8), q8_0 rows and their q8_0x4 packing, and a float
// reference for the GEMV/GEMM outputs.
const q5x8RunSrc = `
// genQ5Row: nb random q5_0 blocks (22 bytes each) and their values.
func genQ5Row(s *lcg, nb int) ([]byte, []float64) {
	x := make([]byte, 22*nb)
	v := make([]float64, 32*nb)
	for b := 0; b < nb; b++ {
		d := s.scale()
		put16(x, 22*b, f16bits(d))
		dv := f16val(f16bits(d))
		var qh uint32
		for j := 0; j < 16; j++ {
			q0 := int(s.next() % 32)
			q1 := int(s.next() % 32)
			x[22*b+6+j] = byte(q0&15) | byte(q1&15)<<4
			qh |= uint32(q0>>4) << j
			qh |= uint32(q1>>4) << (j + 16)
			v[32*b+j] = float64(q0-16) * dv
			v[32*b+j+16] = float64(q1-16) * dv
		}
		x[22*b+2], x[22*b+3], x[22*b+4], x[22*b+5] = byte(qh), byte(qh>>8), byte(qh>>16), byte(qh>>24)
	}
	return x, v
}

// genQ8Row: nb random q8_0 blocks (34 bytes) and their values.
func genQ8Row(s *lcg, nb int) ([]byte, []float64) {
	y := make([]byte, 34*nb)
	v := make([]float64, 32*nb)
	for b := 0; b < nb; b++ {
		d := s.scale()
		put16(y, 34*b, f16bits(d))
		dv := f16val(f16bits(d))
		for j := 0; j < 32; j++ {
			q := s.i8()
			y[34*b+2+j] = byte(q)
			v[32*b+j] = float64(q) * dv
		}
	}
	return y, v
}

// repackQ5_0x8 interleaves eight q5_0 rows into block_q5_0x8 blocks.
func repackQ5_0x8(rows [8][]byte, nb int) []byte {
	out := make([]byte, 176*nb)
	for b := 0; b < nb; b++ {
		o := out[176*b:]
		for c := 0; c < 8; c++ {
			copy(o[2*c:2*c+2], rows[c][22*b:22*b+2])
		}
		for i := 0; i < 16; i++ {
			copy(o[48+8*i:48+8*i+8], rows[i%8][22*b+6+(i/8)*8:22*b+6+(i/8)*8+8])
		}
		for m := 0; m < 8; m++ {
			c0 := 2 * (m % 4)
			hb := m / 4
			o[16+4*m+0] = rows[c0][22*b+2+hb]
			o[16+4*m+1] = rows[c0+1][22*b+2+hb]
			o[16+4*m+2] = rows[c0][22*b+2+2+hb]
			o[16+4*m+3] = rows[c0+1][22*b+2+2+hb]
		}
	}
	return out
}

// packQ8_0x4: four q8_0 rows into block_q8_0x4 blocks (136 bytes).
func packQ8_0x4(rows [4][]byte, nb int) []byte {
	out := make([]byte, 136*nb)
	for b := 0; b < nb; b++ {
		o := out[136*b:]
		for m := 0; m < 4; m++ {
			copy(o[2*m:2*m+2], rows[m][34*b:34*b+2])
			for e := 0; e < 32; e++ {
				o[8+(e/8)*32+m*8+e%8] = rows[m][34*b+2+e]
			}
		}
	}
	return out
}

// runX8Exact pins the GEMM tile to the GEMV path bit for bit: ggml routes
// a row either through the 4-row GEMM or through GEMV depending on the
// batch shape, so the two must agree exactly or batched and sequential
// decodes diverge.
func runX8Exact(t *testing.T, name string, gemv, gemm q5Kernel, n, nc int, seed uint32,
	gen func(*lcg, int) ([]byte, []float64), repack func([8][]byte, int) []byte) {
	t.Helper()
	nb := n / 32
	s := lcg(seed)
	var vx []byte
	for g := 0; g < nc/8; g++ {
		var eight [8][]byte
		for j := 0; j < 8; j++ {
			x, _ := gen(&s, nb)
			eight[j] = x
		}
		vx = append(vx, repack(eight, nb)...)
	}
	var four [4][]byte
	for r := 0; r < 4; r++ {
		four[r], _ = genQ8Row(&s, nb)
	}
	vy := packQ8_0x4(four, nb)
	bs := nc + 8
	sOff, xOff := 256, 256+4*bs*4+64
	yOff := xOff + len(vx) + 64
	mem := make([]byte, yOff+len(vy)+256)
	copy(mem[xOff:], vx)
	copy(mem[yOff:], vy)
	memSize := uint64(len(mem))
	m := &mockModule{memSizePtr: &memSize, mem: unsafe.Pointer(&mem[0])}
	gemm(m, int32(n), int64(sOff), int64(bs), int64(xOff), int64(yOff), 4, int32(nc))
	for r := 0; r < 4; r++ {
		vmem := make([]byte, yOff+len(four[r])+256)
		copy(vmem[xOff:], vx)
		copy(vmem[yOff:], four[r])
		vsize := uint64(len(vmem))
		vm := &mockModule{memSizePtr: &vsize, mem: unsafe.Pointer(&vmem[0])}
		gemv(vm, int32(n), int64(sOff), int64(nc), int64(xOff), int64(yOff), 1, int32(nc))
		for c := 0; c < nc; c++ {
			g, v := get32(mem, sOff+4*(r*bs+c)), get32(vmem, sOff+4*c)
			if g != v {
				t.Fatalf("%s n=%d nc=%d [%d][%d]: gemm %v vs gemv %v: the two paths must be bit-identical", name, n, nc, r, c, g, v)
			}
		}
	}
}

func dotRows(w, a []float64) (float64, float64) {
	var sum, mag float64
	for i := range w {
		p := w[i] * a[i]
		sum += p
		if p < 0 {
			p = -p
		}
		mag += p
	}
	return sum, mag
}

func closeQ5(got float32, want, mag float64) bool {
	d := float64(got) - want
	if d < 0 {
		d = -d
	}
	lim := 1.0
	if want > lim || -want > lim {
		lim = want
		if lim < 0 {
			lim = -lim
		}
	}
	if mag > lim {
		lim = mag
	}
	return d <= 3e-5*lim
}

type q5Kernel func(m *mockModule, l0 int32, l1, l2, l3, l4 int64, l5, l6 int32)

func runGemvQ5(t *testing.T, kernel q5Kernel, n, nc int, seed uint32) {
	t.Helper()
	nb := n / 32
	s := lcg(seed)
	y, yv := genQ8Row(&s, nb)
	var rows [][]float64
	var vx []byte
	for g := 0; g < nc/8; g++ {
		var eight [8][]byte
		for j := 0; j < 8; j++ {
			var v []float64
			eight[j], v = genQ5Row(&s, nb)
			rows = append(rows, v)
		}
		vx = append(vx, repackQ5_0x8(eight, nb)...)
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
			t.Fatalf("gemv q5_0 n=%d nc=%d col %d = %v, want %v", n, nc, c, got, want)
		}
	}
	for off := sOff + 4*nc; off < xOff; off++ {
		if mem[off] != 0 {
			t.Fatalf("gemv q5_0 n=%d nc=%d: byte %d past s written", n, nc, off)
		}
	}
}

func runGemmQ5(t *testing.T, kernel q5Kernel, n, nr, nc int, seed uint32) {
	t.Helper()
	nb := n / 32
	s := lcg(seed)
	var rows [][]float64
	var vx []byte
	for g := 0; g < nc/8; g++ {
		var eight [8][]byte
		for j := 0; j < 8; j++ {
			var v []float64
			eight[j], v = genQ5Row(&s, nb)
			rows = append(rows, v)
		}
		vx = append(vx, repackQ5_0x8(eight, nb)...)
	}
	var yvs [][]float64
	var vy []byte
	for g := 0; g < nr/4; g++ {
		var four [4][]byte
		for r := 0; r < 4; r++ {
			var v []float64
			four[r], v = genQ8Row(&s, nb)
			yvs = append(yvs, v)
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
				t.Fatalf("gemm q5_0 n=%d nr=%d nc=%d [%d][%d] = %v, want %v", n, nr, nc, r, c, got, want)
			}
		}
		for c := nc; c < bs; c++ {
			if get32(mem, sOff+4*(r*bs+c)) != 0 {
				t.Fatalf("gemm q5_0 n=%d nr=%d nc=%d: slack [%d][%d] written", n, nr, nc, r, c)
			}
		}
	}
}
`

const q5x8Decls = "\nfunc GemvKernel(m *mockModule, l0 int32, l1, l2, l3, l4 int64, l5, l6 int32)\nfunc GemmKernel(m *mockModule, l0 int32, l1, l2, l3, l4 int64, l5, l6 int32)\nfunc trapstub()\n\nvar _ = trapstub\n"

const q5x8RunTest = `package quantrun

import "testing"

func TestGemvQ5(t *testing.T) {
	seed := uint32(11)
	for _, n := range []int{32, 64, 256, 896} {
		for _, nc := range []int{8, 16, 24} {
			seed++
			runGemvQ5(t, GemvKernel, n, nc, seed)
		}
	}
}

func TestGemmQ5(t *testing.T) {
	seed := uint32(31)
	for _, n := range []int{32, 64, 256, 896} {
		for _, nr := range []int{4, 8} {
			for _, nc := range []int{8, 16, 24} {
				seed++
				runGemmQ5(t, GemmKernel, n, nr, nc, seed)
			}
		}
	}
}

func TestExactQ5(t *testing.T) {
	for _, n := range []int{32, 256, 896} {
		for _, nc := range []int{8, 24} {
			runX8Exact(t, "q5_0", GemvKernel, GemmKernel, n, nc, uint32(n+nc), genQ5Row, repackQ5_0x8)
		}
	}
}
`

func TestA64Q5_0_8x8KernelGate(t *testing.T) {
	_, argBytes := repackGemmArgs(true)
	pool := NewConstPool("q5_")
	asm := wrap("arm64", "GemvKernel", 16, argBytes, "dotprod", a64GemvQ5_0_8x8Kernel("GemvKernel", pool, true)) +
		wrap("arm64", "GemmKernel", a64GemmQ5Frame, argBytes, "i8mm", a64GemmQ5_0_8x8Kernel("GemmKernel", pool, true)) + pool.Emit()
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "arm64", asm, quantRunCommon+q5x8RunSrc+q5x8Decls, q5x8RunTest)
	runArm64Gate(t, dir, ".", "TestGem[vm]Q5|TestExactQ5", asm)
}

func TestX64Q5_0_8x8KernelShape(t *testing.T) {
	gv := x64GemvQ5_0_8x8Kernel("FnGvavx2", NewConstPool("t_"), true)
	for _, want := range []string{"VPMADDUBSW\tY8, Y5, Y10", "VPHADDD\tY1, Y0, Y0", "VPERMPS\tY2, Y15, Y2", "VPBROADCASTQ\t40(R9), Y12", "VPSUBD\tY11, Y0, Y0"} {
		if !strings.Contains(gv, want) {
			t.Errorf("gemv kernel missing %q", want)
		}
	}
	gm := x64GemmQ5_0_8x8Kernel("FnGmavx2", NewConstPool("t_"), true)
	for _, want := range []string{"VPMADDUBSW\tY12, Y9, Y13", "VPADDD\tY13, Y7, Y7", "VPBROADCASTD\t20(SP), Y8", "VMOVUPS\tY9, 128(SP)", "MOVQ\t176(SP), R11"} {
		if !strings.Contains(gm, want) {
			t.Errorf("gemm kernel missing %q", want)
		}
	}
}

func TestX64Q5_0_8x8KernelGate(t *testing.T) {
	_, argBytes := repackGemmArgs(true)
	pool := NewConstPool("q5x_")
	asm := wrap("amd64", "GemvKernel", 16, argBytes, "avx2", x64GemvQ5_0_8x8Kernel("GemvKernel", pool, true)) +
		wrap("amd64", "GemmKernel", x64GemmQ5Frame, argBytes, "avx2", x64GemmQ5_0_8x8Kernel("GemmKernel", pool, true)) + pool.Emit()
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "amd64", asm, quantRunCommon+q5x8RunSrc+q5x8Decls, q5x8RunTest)
	runAmd64Gate(t, dir, ".", "TestGem[vm]Q5|TestExactQ5", asm)
}
