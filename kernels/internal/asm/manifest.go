package asm

// Manifest describes the assembly overrides in the shape wasm2go's
// -assembly-overrides loader reads (wasm2go docs/assembly-overrides.md).
type Manifest struct {
	Version  int      `json:"version"`
	Memory64 bool     `json:"memory64"`
	Kernels  []Kernel `json:"functions"`
}

// Kernel is one exported function and its bodies. Role and Quant describe
// what the kernel computes; they are not part of the wasm2go manifest
// (which is signatures and bodies only) but of asm/kernels.json, the
// per-kernel index the bundle embeds for embedders that map a model's
// tensors to the native bodies that run them.
type Kernel struct {
	Export string   `json:"export"`
	Role   Role     `json:"-"`
	Quant  string   `json:"-"`
	Params []string `json:"params"`
	Result *string  `json:"result"`
	Bodies []Body   `json:"bodies"`
}

// Role is what a kernel computes for the tensor type in Kernel.Quant.
type Role string

const (
	// RoleGemv is a repack GEMV: one activation row against interleaved
	// weight rows (the token-generation path of a repacked tensor).
	RoleGemv Role = "gemv"
	// RoleGemm is a repack GEMM: a 4-row activation tile against
	// interleaved weight rows (the prompt path of a repacked tensor).
	RoleGemm Role = "gemm"
	// RoleVecDot is the per-row dot product of a tensor left unpacked.
	RoleVecDot Role = "vec_dot"
	// RoleQuantizeMat quantizes a 4-row activation tile into the interleaved
	// activation layout the GEMMs consume (Quant is the activation type).
	RoleQuantizeMat Role = "quantize_mat"
	// RoleOp is any other operator body (attention, softmax, ...); Quant
	// names the element type it works on.
	RoleOp Role = "op"
)

// KernelIndex is asm/kernels.json: every override with its role, the
// tensor type it serves and the architectures that carry a body.
type KernelIndex struct {
	Kernels []IndexedKernel `json:"kernels"`
}

// IndexedKernel is one KernelIndex entry.
type IndexedKernel struct {
	Export string   `json:"export"`
	Role   Role     `json:"role"`
	Quant  string   `json:"quant"`
	Arches []string `json:"arches"`
}

// Index derives the kernel index from the manifest.
func (m *Manifest) Index() *KernelIndex {
	idx := &KernelIndex{}
	for _, k := range m.Kernels {
		var arches []string
		seen := map[string]bool{}
		for _, b := range k.Bodies {
			if !seen[b.Arch] {
				seen[b.Arch] = true
				arches = append(arches, b.Arch)
			}
		}
		idx.Kernels = append(idx.Kernels, IndexedKernel{Export: k.Export, Role: k.Role, Quant: k.Quant, Arches: arches})
	}
	return idx
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
				Role:   RoleGemm,
				Quant:  "q8_0",
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
				Role:   RoleGemv,
				Quant:  "q8_0",
				Params: []string{"i32", "i64", "i64", "i64", "i64", "i32", "i32"},
				Bodies: []Body{
					body("dbg_gemv_q8_0_4x4", "arm64", "dotprod", 16, func(sym string, _ *ConstPool) string { return a64RepackGemvKernel(sym, wide) }),
					body("dbg_gemv_q8_0_4x4", "amd64", "avx512vnni", x64RepackGemvFrame, func(sym string, p *ConstPool) string { return x64RepackGemvKernel(sym, "avx512vnni", p, wide) }),
					body("dbg_gemv_q8_0_4x4", "amd64", "avx2", x64RepackGemvFrame, func(sym string, p *ConstPool) string { return x64RepackGemvKernel(sym, "avx2", p, wide) }),
				},
			},
			{
				Export: "dbg_simd_gemm_f32",
				Role:   RoleGemm,
				Quant:  "f32",
				Params: []string{"i64", "i64", "i64", "i32", "i32", "i32"},
				Bodies: []Body{
					body("dbg_simd_gemm_f32", "arm64", "neon", 16, func(sym string, _ *ConstPool) string { return a64SimdGemmF32Kernel(sym, wide) }),
					body("dbg_simd_gemm_f32", "amd64", "avx2", 16, func(sym string, _ *ConstPool) string { return x64SimdGemmF32Kernel(sym, wide) }),
				},
			},
			{
				Export: "dbg_vec_soft_max_f32",
				Role:   RoleOp,
				Quant:  "f32",
				Params: []string{"i32", "i64", "i64", "f32"},
				Result: str("f64"),
				Bodies: []Body{
					body("dbg_vec_soft_max_f32", "arm64", "neon", 16, func(sym string, p *ConstPool) string { return a64VecSoftMaxKernel(sym, p, wide) }),
					body("dbg_vec_soft_max_f32", "amd64", "avx2", 16, func(sym string, p *ConstPool) string { return x64VecSoftMaxKernel(sym, p, wide) }),
				},
			},
			{
				Export: "dbg_vec_swiglu_f32",
				Role:   RoleOp,
				Quant:  "f32",
				Params: []string{"i32", "i64", "i64", "i64"},
				Bodies: []Body{
					body("dbg_vec_swiglu_f32", "arm64", "neon", 16, func(sym string, p *ConstPool) string { return a64VecSwigluKernel(sym, p, wide) }),
					body("dbg_vec_swiglu_f32", "amd64", "avx2", 16, func(sym string, p *ConstPool) string { return x64VecSwigluKernel(sym, p, wide) }),
				},
			},
			{
				Export: "dbg_vec_dot_f16",
				Role:   RoleVecDot,
				Quant:  "f16",
				Params: []string{"i32", "i64", "i64", "i64", "i64", "i64", "i64", "i32"},
				Bodies: []Body{
					body("dbg_vec_dot_f16", "arm64", "neon", 16, func(sym string, p *ConstPool) string { return a64VecDotF16Kernel(sym, p, wide) }),
					body("dbg_vec_dot_f16", "amd64", "avx2", 16, func(sym string, p *ConstPool) string { return x64VecDotF16Kernel(sym, p, wide) }),
				},
			},
			{
				Export: "dbg_flash_attn_kv_f16",
				Role:   RoleOp,
				Quant:  "f16",
				Params: []string{"i64"},
				Bodies: []Body{
					body("dbg_flash_attn_kv_f16", "arm64", "neon", 16, func(sym string, p *ConstPool) string { return a64FlashAttnKernel(sym, p, wide) }),
					body("dbg_flash_attn_kv_f16", "amd64", "avx2", x64FAFrame, func(sym string, p *ConstPool) string { return x64FlashAttnKernel(sym, p, wide) }),
				},
			},
			{
				Export: "dbg_quantize_mat_q8_K_4x8",
				Role:   RoleQuantizeMat,
				Quant:  "q8_K",
				Params: []string{"i64", "i64", "i64"},
				Bodies: []Body{
					body("dbg_quantize_mat_q8_K_4x8", "arm64", "neon", 16, func(sym string, _ *ConstPool) string { return a64QuantizeMatQ8K4x8Kernel(sym, wide) }),
					body("dbg_quantize_mat_q8_K_4x8", "amd64", "avx2", 16, func(sym string, p *ConstPool) string { return x64QuantizeMatQ8K4x8Kernel(sym, p, wide) }),
				},
			},
			{
				Export: "dbg_quantize_mat_q8_0_4x8",
				Role:   RoleQuantizeMat,
				Quant:  "q8_0",
				Params: []string{"i64", "i64", "i64"},
				Bodies: []Body{
					body("dbg_quantize_mat_q8_0_4x8", "arm64", "neon", 16, func(sym string, _ *ConstPool) string { return a64QuantizeMatQ8_0_4x8Kernel(sym, wide) }),
					body("dbg_quantize_mat_q8_0_4x8", "amd64", "avx2", 16, func(sym string, p *ConstPool) string { return x64QuantizeMatQ8_0_4x8Kernel(sym, p, wide) }),
				},
			},
			{
				Export: "dbg_gemv_iq4_nl_8x8",
				Role:   RoleGemv,
				Quant:  "iq4_nl",
				Params: []string{"i32", "i64", "i64", "i64", "i64", "i32", "i32"},
				Bodies: []Body{
					body("dbg_gemv_iq4_nl_8x8", "arm64", "dotprod", 16, func(sym string, p *ConstPool) string { return a64GemvIQ4NL8x8Kernel(sym, p, wide) }),
					body("dbg_gemv_iq4_nl_8x8", "amd64", "avx2", 16, func(sym string, p *ConstPool) string { return x64GemvIQ4NL8x8Kernel(sym, p, wide) }),
				},
			},
			{
				Export: "dbg_gemm_iq4_nl_8x8",
				Role:   RoleGemm,
				Quant:  "iq4_nl",
				Params: []string{"i32", "i64", "i64", "i64", "i64", "i32", "i32"},
				Bodies: []Body{
					body("dbg_gemm_iq4_nl_8x8", "arm64", "i8mm", a64GemmQ5Frame, func(sym string, p *ConstPool) string { return a64GemmIQ4NL8x8Kernel(sym, p, wide) }),
					body("dbg_gemm_iq4_nl_8x8", "amd64", "avx2", x64GemmQ5Frame, func(sym string, p *ConstPool) string { return x64GemmIQ4NL8x8Kernel(sym, p, wide) }),
				},
			},
			{
				Export: "dbg_gemv_q4_0_8x8",
				Role:   RoleGemv,
				Quant:  "q4_0",
				Params: []string{"i32", "i64", "i64", "i64", "i64", "i32", "i32"},
				Bodies: []Body{
					body("dbg_gemv_q4_0_8x8", "arm64", "dotprod", 16, func(sym string, p *ConstPool) string { return a64GemvQ4_0_8x8Kernel(sym, p, wide) }),
					body("dbg_gemv_q4_0_8x8", "amd64", "avx2", 16, func(sym string, p *ConstPool) string { return x64GemvQ4_0_8x8Kernel(sym, p, wide) }),
				},
			},
			{
				Export: "dbg_gemm_q4_0_8x8",
				Role:   RoleGemm,
				Quant:  "q4_0",
				Params: []string{"i32", "i64", "i64", "i64", "i64", "i32", "i32"},
				Bodies: []Body{
					body("dbg_gemm_q4_0_8x8", "arm64", "i8mm", a64GemmQ5Frame, func(sym string, p *ConstPool) string { return a64GemmQ4_0_8x8Kernel(sym, p, wide) }),
					body("dbg_gemm_q4_0_8x8", "amd64", "avx2", x64GemmQ5Frame, func(sym string, p *ConstPool) string { return x64GemmQ4_0_8x8Kernel(sym, p, wide) }),
				},
			},
			{
				Export: "dbg_gemv_q5_0_8x8",
				Role:   RoleGemv,
				Quant:  "q5_0",
				Params: []string{"i32", "i64", "i64", "i64", "i64", "i32", "i32"},
				Bodies: []Body{
					body("dbg_gemv_q5_0_8x8", "arm64", "dotprod", 16, func(sym string, p *ConstPool) string { return a64GemvQ5_0_8x8Kernel(sym, p, wide) }),
					body("dbg_gemv_q5_0_8x8", "amd64", "avx2", 16, func(sym string, p *ConstPool) string { return x64GemvQ5_0_8x8Kernel(sym, p, wide) }),
				},
			},
			{
				Export: "dbg_gemm_q5_0_8x8",
				Role:   RoleGemm,
				Quant:  "q5_0",
				Params: []string{"i32", "i64", "i64", "i64", "i64", "i32", "i32"},
				Bodies: []Body{
					body("dbg_gemm_q5_0_8x8", "arm64", "i8mm", a64GemmQ5Frame, func(sym string, p *ConstPool) string { return a64GemmQ5_0_8x8Kernel(sym, p, wide) }),
					body("dbg_gemm_q5_0_8x8", "amd64", "avx2", x64GemmQ5Frame, func(sym string, p *ConstPool) string { return x64GemmQ5_0_8x8Kernel(sym, p, wide) }),
				},
			},
			{
				Export: "dbg_gemv_q4_K_8x8",
				Role:   RoleGemv,
				Quant:  "q4_K",
				Params: []string{"i32", "i64", "i64", "i64", "i64", "i32", "i32"},
				Bodies: []Body{
					body("dbg_gemv_q4_K_8x8", "arm64", "dotprod", 16, func(sym string, _ *ConstPool) string { return a64GemvQ4K8x8Kernel(sym, wide) }),
					body("dbg_gemv_q4_K_8x8", "amd64", "avx2", x64Q4KFrame, func(sym string, p *ConstPool) string { return x64GemvQ4K8x8Kernel(sym, p, wide) }),
				},
			},
			{
				Export: "dbg_gemm_q4_K_8x8",
				Role:   RoleGemm,
				Quant:  "q4_K",
				Params: []string{"i32", "i64", "i64", "i64", "i64", "i32", "i32"},
				Bodies: []Body{
					body("dbg_gemm_q4_K_8x8", "arm64", "i8mm", a64GemmQ4KFrame, func(sym string, _ *ConstPool) string { return a64GemmQ4K8x8Kernel(sym, wide) }),
					body("dbg_gemm_q4_K_8x8", "amd64", "avx2", x64Q4KTileFrame, func(sym string, p *ConstPool) string { return x64GemmQ4K8x8Kernel(sym, p, wide) }),
				},
			},
			{
				Export: "dbg_gemv_q5_K_8x8",
				Role:   RoleGemv,
				Quant:  "q5_K",
				Params: []string{"i32", "i64", "i64", "i64", "i64", "i32", "i32"},
				Bodies: []Body{
					body("dbg_gemv_q5_K_8x8", "arm64", "dotprod", 16, func(sym string, _ *ConstPool) string { return a64GemvQ5K8x8Kernel(sym, wide) }),
					body("dbg_gemv_q5_K_8x8", "amd64", "avx2", x64Q4KFrame, func(sym string, p *ConstPool) string { return x64GemvQ5K8x8Kernel(sym, p, wide) }),
				},
			},
			{
				Export: "dbg_gemm_q5_K_8x8",
				Role:   RoleGemm,
				Quant:  "q5_K",
				Params: []string{"i32", "i64", "i64", "i64", "i64", "i32", "i32"},
				Bodies: []Body{
					body("dbg_gemm_q5_K_8x8", "arm64", "i8mm", a64GemmQ4KFrame, func(sym string, _ *ConstPool) string { return a64GemmQ5K8x8Kernel(sym, wide) }),
					body("dbg_gemm_q5_K_8x8", "amd64", "avx2", x64Q4KTileFrame, func(sym string, p *ConstPool) string { return x64GemmQ5K8x8Kernel(sym, p, wide) }),
				},
			},
			{
				Export: "dbg_gemv_q6_K_8x8",
				Role:   RoleGemv,
				Quant:  "q6_K",
				Params: []string{"i32", "i64", "i64", "i64", "i64", "i32", "i32"},
				Bodies: []Body{
					body("dbg_gemv_q6_K_8x8", "arm64", "dotprod", 16, func(sym string, _ *ConstPool) string { return a64GemvQ6K8x8Kernel(sym, wide) }),
					body("dbg_gemv_q6_K_8x8", "amd64", "avx2", x64Q6KFrame, func(sym string, p *ConstPool) string { return x64GemvQ6K8x8Kernel(sym, p, wide) }),
				},
			},
			{
				Export: "dbg_gemm_q6_K_8x8",
				Role:   RoleGemm,
				Quant:  "q6_K",
				Params: []string{"i32", "i64", "i64", "i64", "i64", "i32", "i32"},
				Bodies: []Body{
					body("dbg_gemm_q6_K_8x8", "arm64", "i8mm", a64GemmQ6KFrame, func(sym string, _ *ConstPool) string { return a64GemmQ6K8x8Kernel(sym, wide) }),
					body("dbg_gemm_q6_K_8x8", "amd64", "avx2", x64Q6KTileFrame, func(sym string, p *ConstPool) string { return x64GemmQ6K8x8Kernel(sym, p, wide) }),
				},
			},
			{
				Export: "dbg_vec_dot_iq4_nl_q8_0",
				Role:   RoleVecDot,
				Quant:  "iq4_nl",
				Params: []string{"i32", "i64", "i64", "i64", "i64", "i64", "i64", "i32"},
				Bodies: []Body{
					body("dbg_vec_dot_iq4_nl_q8_0", "arm64", "dotprod", 16, func(sym string, p *ConstPool) string { return a64VecDotIQ4NLKernel(sym, p, wide) }),
					body("dbg_vec_dot_iq4_nl_q8_0", "amd64", "avx2", 16, func(sym string, p *ConstPool) string { return x64VecDotIQ4NLKernel(sym, p, wide) }),
				},
			},
			{
				Export: "dbg_vec_dot_q5_1_q8_1",
				Role:   RoleVecDot,
				Quant:  "q5_1",
				Params: []string{"i32", "i64", "i64", "i64", "i64", "i64", "i64", "i32"},
				Bodies: []Body{
					body("dbg_vec_dot_q5_1_q8_1", "arm64", "dotprod", 16, func(sym string, p *ConstPool) string { return a64VecDotQ5_1Kernel(sym, p, wide) }),
					body("dbg_vec_dot_q5_1_q8_1", "amd64", "avx2", 16, func(sym string, p *ConstPool) string { return x64VecDotQ5_1Kernel(sym, p, wide) }),
				},
			},
			{
				Export: "dbg_vec_dot_q4_1_q8_1",
				Role:   RoleVecDot,
				Quant:  "q4_1",
				Params: []string{"i32", "i64", "i64", "i64", "i64", "i64", "i64", "i32"},
				Bodies: []Body{
					body("dbg_vec_dot_q4_1_q8_1", "arm64", "dotprod", 16, func(sym string, p *ConstPool) string { return a64VecDotQ4_1Kernel(sym, p, wide) }),
					body("dbg_vec_dot_q4_1_q8_1", "amd64", "avx2", 16, func(sym string, p *ConstPool) string { return x64VecDotQ4_1Kernel(sym, p, wide) }),
				},
			},
			{
				Export: "dbg_vec_dot_q4_0_q8_0",
				Role:   RoleVecDot,
				Quant:  "q4_0",
				Params: []string{"i32", "i64", "i64", "i64", "i64", "i64", "i64", "i32"},
				Bodies: []Body{
					body("dbg_vec_dot_q4_0_q8_0", "arm64", "dotprod", 16, func(sym string, p *ConstPool) string { return a64VecDotQ4_0Kernel(sym, p, wide) }),
					body("dbg_vec_dot_q4_0_q8_0", "amd64", "avx2", 16, func(sym string, p *ConstPool) string { return x64VecDotQ4_0Kernel(sym, p, wide) }),
				},
			},
			{
				Export: "dbg_vec_dot_q8_0_q8_0",
				Role:   RoleVecDot,
				Quant:  "q8_0",
				Params: []string{"i32", "i64", "i64", "i64", "i64", "i64", "i64", "i32"},
				Bodies: []Body{
					body("dbg_vec_dot_q8_0_q8_0", "arm64", "dotprod", 16, func(sym string, p *ConstPool) string { return a64VecDotQ8_0Kernel(sym, p, wide) }),
					body("dbg_vec_dot_q8_0_q8_0", "amd64", "avx2", 16, func(sym string, p *ConstPool) string { return x64VecDotQ8_0Kernel(sym, p, wide) }),
				},
			},
			{
				Export: "dbg_vec_dot_q5_0_q8_0",
				Role:   RoleVecDot,
				Quant:  "q5_0",
				Params: []string{"i32", "i64", "i64", "i64", "i64", "i64", "i64", "i32"},
				Bodies: []Body{
					body("dbg_vec_dot_q5_0_q8_0", "arm64", "dotprod", 16, func(sym string, p *ConstPool) string { return a64VecDotQ5_0Kernel(sym, p, wide) }),
					body("dbg_vec_dot_q5_0_q8_0", "amd64", "avx2", 16, func(sym string, p *ConstPool) string { return x64VecDotQ5_0Kernel(sym, p, wide) }),
				},
			},
			{
				Export: "dbg_vec_dot_q2_K_q8_K",
				Role:   RoleVecDot,
				Quant:  "q2_K",
				Params: []string{"i32", "i64", "i64", "i64", "i64", "i64", "i64", "i32"},
				Bodies: []Body{
					body("dbg_vec_dot_q2_K_q8_K", "arm64", "dotprod", 16, func(sym string, p *ConstPool) string { return a64VecDotQ2_KKernel(sym, p, wide) }),
					body("dbg_vec_dot_q2_K_q8_K", "amd64", "avx2", 16, func(sym string, p *ConstPool) string { return x64VecDotQ2_KKernel(sym, p, wide) }),
				},
			},
			{
				Export: "dbg_vec_dot_q3_K_q8_K",
				Role:   RoleVecDot,
				Quant:  "q3_K",
				Params: []string{"i32", "i64", "i64", "i64", "i64", "i64", "i64", "i32"},
				Bodies: []Body{
					body("dbg_vec_dot_q3_K_q8_K", "arm64", "dotprod", 16, func(sym string, p *ConstPool) string { return a64VecDotQ3_KKernel(sym, p, wide) }),
					body("dbg_vec_dot_q3_K_q8_K", "amd64", "avx2", 16, func(sym string, p *ConstPool) string { return x64VecDotQ3_KKernel(sym, p, wide) }),
				},
			},
			{
				Export: "dbg_vec_dot_q5_K_q8_K",
				Role:   RoleVecDot,
				Quant:  "q5_K",
				Params: []string{"i32", "i64", "i64", "i64", "i64", "i64", "i64", "i32"},
				Bodies: []Body{
					body("dbg_vec_dot_q5_K_q8_K", "arm64", "dotprod", 16, func(sym string, p *ConstPool) string { return a64VecDotQ5_KKernel(sym, p, wide) }),
					body("dbg_vec_dot_q5_K_q8_K", "amd64", "avx2", 16, func(sym string, p *ConstPool) string { return x64VecDotQ5_KKernel(sym, p, wide) }),
				},
			},
			{
				Export: "dbg_vec_dot_q4_K_q8_K",
				Role:   RoleVecDot,
				Quant:  "q4_K",
				Params: []string{"i32", "i64", "i64", "i64", "i64", "i64", "i64", "i32"},
				Bodies: []Body{
					body("dbg_vec_dot_q4_K_q8_K", "arm64", "dotprod", 16, func(sym string, p *ConstPool) string { return a64VecDotQ4_KKernel(sym, p, wide) }),
					body("dbg_vec_dot_q4_K_q8_K", "amd64", "avx2", 16, func(sym string, p *ConstPool) string { return x64VecDotQ4_KKernel(sym, p, wide) }),
				},
			},
			{
				Export: "dbg_vec_dot_q6_K_q8_K",
				Role:   RoleVecDot,
				Quant:  "q6_K",
				Params: []string{"i32", "i64", "i64", "i64", "i64", "i64", "i64", "i32"},
				Bodies: []Body{
					body("dbg_vec_dot_q6_K_q8_K", "arm64", "dotprod", 16, func(sym string, p *ConstPool) string { return a64VecDotQ6_KKernel(sym, p, wide) }),
					body("dbg_vec_dot_q6_K_q8_K", "amd64", "avx2", 16, func(sym string, p *ConstPool) string { return x64VecDotQ6_KKernel(sym, p, wide) }),
				},
			},
			{
				Export: "dbg_vec_mad_f16_f32",
				Role:   RoleOp,
				Quant:  "f16",
				Params: []string{"i32", "i64", "i64", "f32"},
				Bodies: []Body{
					body("dbg_vec_mad_f16_f32", "arm64", "neon", 16, func(sym string, p *ConstPool) string { return a64VecMadF16F32Kernel(sym, p, wide) }),
					body("dbg_vec_mad_f16_f32", "amd64", "avx2", 16, func(sym string, p *ConstPool) string { return x64VecMadF16F32Kernel(sym, p, wide) }),
				},
			},
		},
	}
}
