package asm

// Manifest describes the assembly overrides in the shape wasm2go's
// -assembly-overrides loader reads (wasm2go docs/assembly-overrides.md).
type Manifest struct {
	Version  int      `json:"version"`
	Memory64 bool     `json:"memory64"`
	Kernels  []Kernel `json:"functions"`
}

// Kernel is one exported function and its bodies.
type Kernel struct {
	Export string   `json:"export"`
	Params []string `json:"params"`
	Result *string  `json:"result"`
	Bodies []Body   `json:"bodies"`
}

// Body is one architecture/feature-level body. Text is the assembly
// (written to File by the generator, not part of the manifest).
type Body struct {
	Arch    string `json:"arch"`
	Feature string `json:"feature"`
	Frame   int    `json:"frame"`
	File    string `json:"file"`
	Text    string `json:"-"`
}

func str(s string) *string { return &s }

// Overrides returns the current set of overrides for the memory64 build
// of llama.wasm: the exports the wasm build exposes under dbg_* (see
// patches/) with the bodies internal/asm generates for them.
//
// Every entry pairs with a wasm2go issue tracking the generic lowering
// that would retire it; see kernels/README.md.
func Overrides() *Manifest {
	const wide = true
	body := func(export, arch, feature string, frame int, gen func(sym string, pool *ConstPool) string) Body {
		pool := NewConstPool(export + "_" + feature + "_")
		text := gen(export, pool)
		if consts := pool.Emit(); consts != "" {
			text += "\n" + consts
		}
		return Body{Arch: arch, Feature: feature, Frame: frame, Text: text}
	}
	return &Manifest{
		Version:  1,
		Memory64: true,
		Kernels: []Kernel{
			{
				Export: "dbg_gemm_q8_0_4x4",
				Params: []string{"i32", "i64", "i64", "i64", "i64", "i32", "i32"},
				Bodies: []Body{
					body("dbg_gemm_q8_0_4x4", "arm64", "i8mm", a64RepackGemmFrame, func(sym string, _ *ConstPool) string { return a64RepackGemmKernel(sym, "i8mm", wide) }),
					body("dbg_gemm_q8_0_4x4", "arm64", "dotprod", a64RepackGemmFrame, func(sym string, _ *ConstPool) string { return a64RepackGemmKernel(sym, "dotprod", wide) }),
					body("dbg_gemm_q8_0_4x4", "amd64", "avx512vnni", x64RepackGemmFrame, func(sym string, p *ConstPool) string { return x64RepackGemmKernel(sym, "avx512vnni", p, wide) }),
					body("dbg_gemm_q8_0_4x4", "amd64", "avx2", x64RepackGemmFrame, func(sym string, p *ConstPool) string { return x64RepackGemmKernel(sym, "avx2", p, wide) }),
				},
			},
			{
				Export: "dbg_gemv_q8_0_4x4",
				Params: []string{"i32", "i64", "i64", "i64", "i64", "i32", "i32"},
				Bodies: []Body{
					body("dbg_gemv_q8_0_4x4", "arm64", "dotprod", 16, func(sym string, _ *ConstPool) string { return a64RepackGemvKernel(sym, wide) }),
					body("dbg_gemv_q8_0_4x4", "amd64", "avx512vnni", x64RepackGemvFrame, func(sym string, p *ConstPool) string { return x64RepackGemvKernel(sym, "avx512vnni", p, wide) }),
					body("dbg_gemv_q8_0_4x4", "amd64", "avx2", x64RepackGemvFrame, func(sym string, p *ConstPool) string { return x64RepackGemvKernel(sym, "avx2", p, wide) }),
				},
			},
			{
				Export: "dbg_simd_gemm_f32",
				Params: []string{"i64", "i64", "i64", "i32", "i32", "i32"},
				Bodies: []Body{
					body("dbg_simd_gemm_f32", "arm64", "neon", 16, func(sym string, _ *ConstPool) string { return a64SimdGemmF32Kernel(sym, wide) }),
					body("dbg_simd_gemm_f32", "amd64", "avx2", 16, func(sym string, _ *ConstPool) string { return x64SimdGemmF32Kernel(sym, wide) }),
				},
			},
			{
				Export: "dbg_vec_soft_max_f32",
				Params: []string{"i32", "i64", "i64", "f32"},
				Result: str("f64"),
				Bodies: []Body{
					body("dbg_vec_soft_max_f32", "arm64", "neon", 16, func(sym string, p *ConstPool) string { return a64VecSoftMaxKernel(sym, p, wide) }),
					body("dbg_vec_soft_max_f32", "amd64", "avx2", 16, func(sym string, p *ConstPool) string { return x64VecSoftMaxKernel(sym, p, wide) }),
				},
			},
			{
				Export: "dbg_vec_swiglu_f32",
				Params: []string{"i32", "i64", "i64", "i64"},
				Bodies: []Body{
					body("dbg_vec_swiglu_f32", "arm64", "neon", 16, func(sym string, p *ConstPool) string { return a64VecSwigluKernel(sym, p, wide) }),
					body("dbg_vec_swiglu_f32", "amd64", "avx2", 16, func(sym string, p *ConstPool) string { return x64VecSwigluKernel(sym, p, wide) }),
				},
			},
			{
				Export: "dbg_vec_dot_f16",
				Params: []string{"i32", "i64", "i64", "i64", "i64", "i64", "i64", "i32"},
				Bodies: []Body{
					body("dbg_vec_dot_f16", "arm64", "neon", 16, func(sym string, p *ConstPool) string { return a64VecDotF16Kernel(sym, p, wide) }),
					body("dbg_vec_dot_f16", "amd64", "avx2", 16, func(sym string, p *ConstPool) string { return x64VecDotF16Kernel(sym, p, wide) }),
				},
			},
			{
				Export: "dbg_vec_mad_f16_f32",
				Params: []string{"i32", "i64", "i64", "f32"},
				Bodies: []Body{
					body("dbg_vec_mad_f16_f32", "arm64", "neon", 16, func(sym string, p *ConstPool) string { return a64VecMadF16F32Kernel(sym, p, wide) }),
					body("dbg_vec_mad_f16_f32", "amd64", "avx2", 16, func(sym string, p *ConstPool) string { return x64VecMadF16F32Kernel(sym, p, wide) }),
				},
			},
		},
	}
}
