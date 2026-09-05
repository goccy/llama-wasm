package asm

import "testing"

// Edge-value gates for the quantized dots: the random gates cover
// typical bytes; these pin the extremes (saturated 6-bit scales and
// mins, all-set high bits, maximal activations, negative scales) that
// a lane or bit dropped in the unpack would only show at.

const kQuantEdgeRunSrc = `
// fillEdge writes pattern p into every byte of b.
func fillEdge(b []byte, p byte) {
	for i := range b {
		b[i] = p
	}
}

// genQ8_KEdge: activations all v with consistent bsums.
func genQ8_KEdge(nb int, v int8, d float32) ([]byte, []float64) {
	y := make([]byte, nb*292)
	vals := make([]float64, nb*256)
	for b := 0; b < nb; b++ {
		yb := y[b*292:]
		put32(yb, 0, d)
		for i := 0; i < 256; i++ {
			yb[4+i] = byte(v)
			vals[b*256+i] = float64(d) * float64(v)
		}
		for i := 0; i < 16; i++ {
			put16(yb, 260+2*i, uint16(int16(16*int(v))))
		}
	}
	return y, vals
}

func edgeQ4_K(t *testing.T, kernel dotKernel, scaleByte, qByte byte, v int8) {
	t.Helper()
	const n = 512
	nb := n / 256
	x := make([]byte, nb*144)
	y, yv := genQ8_KEdge(nb, v, 0.25)
	var want float64
	for b := 0; b < nb; b++ {
		xb := x[b*144:]
		d, dmin := f16bits(1.5), f16bits(0.75)
		put16(xb, 0, d)
		put16(xb, 2, dmin)
		fillEdge(xb[4:16], scaleByte)
		fillEdge(xb[16:144], qByte)
		for j := 0; j < 8; j++ {
			sc, m := scaleMinK4(xb[4:16], j)
			for i := 0; i < 32; i++ {
				q := int(xb[16+32*(j/2)+i])
				if j%2 == 0 {
					q &= 0xf
				} else {
					q >>= 4
				}
				want += (f16val(d)*float64(sc)*float64(q) - f16val(dmin)*float64(m)) * yv[b*256+32*j+i]
			}
		}
	}
	if got := callDot(t, kernel, n, x, y); !close32(got, want, 1e-5) {
		t.Fatalf("q4_K edge scales=%#x q=%#x v=%d: %v, want %v", scaleByte, qByte, v, got, want)
	}
}

func edgeQ6_K(t *testing.T, kernel dotKernel, scale int8, qlByte, qhByte byte, v int8) {
	t.Helper()
	const n = 512
	nb := n / 256
	x := make([]byte, nb*210)
	y, yv := genQ8_KEdge(nb, v, 0.125)
	var want float64
	for b := 0; b < nb; b++ {
		xb := x[b*210:]
		fillEdge(xb[0:128], qlByte)
		fillEdge(xb[128:192], qhByte)
		fillEdge(xb[192:208], byte(scale))
		d := f16bits(0.5)
		put16(xb, 208, d)
		for h := 0; h < 2; h++ {
			ql, qh, sc := xb[64*h:], xb[128+32*h:], xb[192+8*h:]
			for l := 0; l < 32; l++ {
				is := l / 16
				q1 := int(ql[l]&0xf|(qh[l]>>0&3)<<4) - 32
				q2 := int(ql[l+32]&0xf|(qh[l]>>2&3)<<4) - 32
				q3 := int(ql[l]>>4|(qh[l]>>4&3)<<4) - 32
				q4 := int(ql[l+32]>>4|(qh[l]>>6&3)<<4) - 32
				base := b*256 + 128*h + l
				want += f16val(d) * float64(int8(sc[is+0])) * float64(q1) * yv[base]
				want += f16val(d) * float64(int8(sc[is+2])) * float64(q2) * yv[base+32]
				want += f16val(d) * float64(int8(sc[is+4])) * float64(q3) * yv[base+64]
				want += f16val(d) * float64(int8(sc[is+6])) * float64(q4) * yv[base+96]
			}
		}
	}
	if got := callDot(t, kernel, n, x, y); !close32(got, want, 1e-5) {
		t.Fatalf("q6_K edge scale=%d ql=%#x qh=%#x v=%d: %v, want %v", scale, qlByte, qhByte, v, got, want)
	}
}

func runEdges(t *testing.T, q4, q6 dotKernel) {
	for _, sb := range []byte{0xff, 0x3f, 0xc0, 0x00, 0x55, 0xaa} {
		for _, qb := range []byte{0xff, 0x0f, 0xf0, 0x00, 0x5a} {
			for _, v := range []int8{127, -128, 1, -1} {
				edgeQ4_K(t, q4, sb, qb, v)
			}
		}
	}
	for _, sc := range []int8{127, -128, 1, -1, 0} {
		for _, ql := range []byte{0xff, 0x0f, 0xf0, 0x00} {
			for _, qh := range []byte{0xff, 0x00, 0x55, 0xaa, 0xc0, 0x03} {
				for _, v := range []int8{127, -128, 1} {
					edgeQ6_K(t, q6, sc, ql, qh, v)
				}
			}
		}
	}
}
`

const kQuantEdgeRunTest = `package quantrun

import "testing"

func TestKQuantEdges(t *testing.T) { runEdges(t, Q4KKernel, Q6KKernel) }
`

func TestA64VecDotKQuantEdgeGate(t *testing.T) {
	_, argBytes := vecDotArgs(true)
	asm := wrap("arm64", "Q4KKernel", 16, argBytes, "dotprod", a64VecDotQ4_KKernel("Q4KKernel", nil, true)) +
		wrap("arm64", "Q6KKernel", 16, argBytes, "dotprod", a64VecDotQ6_KKernel("Q6KKernel", nil, true))
	dir := t.TempDir()
	writeRunTree(t, dir, "quantrun", "arm64", asm, quantRunCommon+kQuantRunSrc+kQuantEdgeRunSrc+kQuantDecls, kQuantEdgeRunTest)
	runArm64Gate(t, dir, ".", "TestKQuantEdges", asm)
}
