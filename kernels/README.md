# kernels — assembly bodies for the hot leaf functions

wasm2go lowers `llama.wasm` from the wasm itself. For a handful of leaf
compute kernels its lowering is still well short of what the CPU can
do, and this directory supplies those bodies by hand through wasm2go's
**assembly-override** mechanism (see `docs/asm-overrides.md` in
wasm2go): the wasm build exports each kernel under a `dbg_*` name (see
`patches/`), `asm/overrides.json` names the exports with their wasm
signatures, `asm/kernels.json` indexes them by role and tensor type
(embedded in the bundle as `base.AsmKernels`), and `asm/*.s` hold one
body per architecture and CPU feature level. wasm2go validates the manifest against the module,
wraps each body in its fixed ABI, dispatches on CPU features at run
time, and keeps its own lowering as the fallback.

The transpiler learns nothing about ggml from this: everything that
knows a block layout lives here.

## The boundary

A body must stay inside the wasm execution model:

- linear memory only, through the base and size wasm2go hands it, every
  range checked before use and a miss sent to `ovr_oob` (the module's
  out-of-bounds trap);
- no calls: no host imports, no other functions, no Go runtime;
- the same result as the wasm function, up to the rounding this
  project has accepted under wasm2go's fast-math option (fused
  multiply-add, accumulation order).

Overrides are a stop-gap, not a second backend. Every entry below is
expected to disappear once wasm2go can lower the kernel from the wasm;
the budget is the table, and adding to it needs the wasm2go issue that
would retire the addition.

| export | what | bodies | retire when wasm2go can… |
|---|---|---|---|
| `dbg_gemm_q8_0_4x4` | q8_0x4 repack GEMM (prompt matmul) | arm64 i8mm/dotprod, amd64 avx512vnni/avx2 | lower register-blocked int8 GEMM (SMMLA/VNNI) from the wasm loop |
| `dbg_gemv_q8_0_4x4` | q8_0x4 repack GEMV (decode matmul) | arm64 dotprod, amd64 avx512vnni/avx2 | hoist bounds checks and the f16 scale lookups out of the wasm GEMV loop |
| `dbg_simd_gemm_f32` | f32 micro-GEMM (flash-attention tiles) | arm64 neon, amd64 avx2 | fuse the f32 FMA tile loop |
| `dbg_vec_soft_max_f32` | soft_max row (exp + sum) | arm64 neon, amd64 avx2 | keep the SIMD exp loop in registers with hoisted bounds checks |
| `dbg_vec_swiglu_f32` | SwiGLU row | arm64 neon, amd64 avx2 | same as soft_max |
| `dbg_vec_dot_f16` | f16 dot (single-query attention K·Q) | arm64 neon, amd64 avx2 | lower the f16-table gather to FCVTL/VCVTPH2PS + FMA |
| `dbg_vec_mad_f16_f32` | f16-by-f32 multiply-add (attention V accumulate) | arm64 neon, amd64 avx2 | same as `dbg_vec_dot_f16` |
| `dbg_gemv_iq4_nl_8x8` | iq4_nl_8x8 repack GEMV (IQ4_NL decode matmul, rows a multiple of 8) | arm64 dotprod, amd64 avx2 | the q4_0 body with the nibbles looked up in kvalues_iq4nl (TBL signed / VPSHUFB table+127 with 127 x block sums folded out) |
| `dbg_gemm_iq4_nl_8x8` | iq4_nl_8x8 x q8_0x4 repack GEMM (IQ4_NL prompt matmul) | arm64 i8mm, amd64 avx2 | the q4_0 tile with the kvalues lookup |
| `dbg_gemv_q4_0_8x8` | q4_0_8x8 repack GEMV (Q4_0 decode matmul, rows a multiple of 8) | arm64 dotprod, amd64 avx2 | the q5_0 body without fifth bits, -8 folded through the block sum |
| `dbg_gemm_q4_0_8x8` | q4_0_8x8 x q8_0x4 repack GEMM (Q4_0 prompt matmul) | arm64 i8mm, amd64 avx2 | the q5_0 tile without fifth bits |
| `dbg_gemv_q5_0_8x8` | q5_0_8x8 repack GEMV (Q5_0 decode matmul, rows a multiple of 8) | arm64 dotprod, amd64 avx2 | SDOT/VPMADDUBSW over the eight interleaved rows, fifth bits expanded with TBL/VPSHUFB, -16 folded through the block sum |
| `dbg_gemm_q5_0_8x8` | q5_0_8x8 x q8_0x4 repack GEMM (Q5_0 prompt matmul; native x86 reaches a GEMM here through llamafile sgemm) | arm64 i8mm, amd64 avx2 | SMMLA 2x2 tiles / four activation rows per unpacked run |
| `dbg_quantize_mat_q8_0_4x8` | f32 rows -> block_q8_0x4 (the 8-wide repack GEMMs' activation quantizer; ggml has only a scalar body, the wasm patch adds a SIMD one that rounds to nearest even like `quantize_row_q8_0`, which feeds the same tensors' GEMV path) | arm64 neon, amd64 avx2 | FMAXV amax, FCVTNS quants |
| `dbg_quantize_mat_q8_K_4x8` | f32 rows -> block_q8_Kx4 (the repack GEMM's activation quantizer; scalar in every ggml build) | arm64 neon, amd64 avx2 | FMAXV/FMINV max, FCVTNS quants, ADDV chunk sums |
| `dbg_gemv_q4_K_8x8` | q4_K_8x8 repack GEMV (Q4_K decode matmul, rows a multiple of 8) | arm64 dotprod, amd64 avx2 | lower the 8-row nibble dot to SDOT/VPMADDUBSW with the 6-bit scales decoded once per block |
| `dbg_gemm_q4_K_8x8` | q4_K_8x8 x q8_Kx4 repack GEMM (Q4_K prompt matmul) | arm64 i8mm, amd64 avx2 | register-blocked 8x4 int8 tile (SMMLA / VPMADDUBSW) with the block sums folded in as a bias |
| `dbg_gemv_q5_K_8x8` | q5_K_8x8 repack GEMV (Q5_K decode matmul, rows a multiple of 8) | arm64 dotprod, amd64 avx2 | the q4_K body with the fifth bit of every quant merged from qh |
| `dbg_gemm_q5_K_8x8` | q5_K_8x8 x q8_Kx4 repack GEMM (Q5_K prompt matmul) | arm64 i8mm, amd64 avx2 | the q4_K tile with the fifth bits merged from qh |
| `dbg_gemv_q6_K_8x8` | q6_K_8x8 repack GEMV (Q6_K decode matmul, rows a multiple of 8) | arm64 dotprod, amd64 avx2 | 6-bit quants rebuilt unsigned from ql nibbles and qh bit pairs, SDOT/VPMADDUBSW over the eight interleaved rows, i8 sub-block scales as i32 lane multiplies, -32 folded through the block sums |
| `dbg_gemm_q6_K_8x8` | q6_K_8x8 x q8_Kx4 repack GEMM (Q6_K prompt matmul) | arm64 i8mm, amd64 avx2 | SMMLA 2x2 tiles over centred quants / four activation rows per 6-bit unpack with the block sums folded in as a bias |
| `dbg_vec_dot_iq4_nl_q8_0` | iq4_nl x q8_0 dot (IQ4_NL rows that are not repacked) | arm64 dotprod, amd64 avx2 | TBL / VPSHUFB through the signed kvalues table, then SDOT / the sign-trick pair dot |
| `dbg_vec_dot_q5_1_q8_1` | q5_1 x q8_1 dot (Q5_1 rows) | arm64 dotprod, amd64 avx2 | the q5_0 dot on unsigned quants plus the block min term m * s |
| `dbg_vec_dot_q4_1_q8_1` | q4_1 x q8_1 dot (Q4_1 rows) | arm64 dotprod, amd64 avx2 | nibbles unsigned, SDOT / VPMADDUBSW, plus the block min term |
| `dbg_vec_dot_q5_0_q8_0` | q5_0 x q8_0 dot (the matmul of tensors K-quants cannot cover, e.g. Qwen2.5-0.5B's 896-wide rows) | arm64 dotprod, amd64 avx2 | lower the fifth-bit gather + i16 dot pairs to CMTST/SDOT |
| `dbg_vec_dot_q4_0_q8_0` | q4_0 x q8_0 dot (the per-row path of a Q4_0 tensor the backend does not repack, e.g. a shared token embedding used as the output projection) | arm64 dotprod, amd64 avx2 | lower the nibble unpack + i16 dot pairs to SDOT |
| `dbg_vec_dot_q8_0_q8_0` | q8_0 x q8_0 dot (same role for Q8_0 tensors) | arm64 dotprod, amd64 avx2 | lower the i16 dot pairs to SDOT |
| `dbg_vec_dot_q5_K_q8_K` | q5_K x q8_K dot (Q5_K rows that are not repacked; 2x2 tile for nrc 2) | arm64 dotprod, amd64 avx2 | the q4_K dot with the fifth bit of every quant merged from qh |
| `dbg_vec_dot_q2_K_q8_K` | q2_K x q8_K dot (Q2_K rows) | arm64 dotprod, amd64 avx2 | 2-bit fields shifted out of 32-byte loads, SDOT/VPMADDUBSW per 16-quant sub-block, nibble scales as lane multiplies, mins through the block sums |
| `dbg_vec_dot_q3_K_q8_K` | q3_K x q8_K dot (Q3_K rows) | arm64 dotprod, amd64 avx2 | quants rebuilt unsigned (2-bit field + hmask bit), 6-bit scales unpacked and centred, -4 folded through the block sums |
| `dbg_vec_dot_q4_K_q8_K` | q4_K x q8_K dot (Q4_K_M matmul, rows not a multiple of 8) | arm64 dotprod, amd64 avx2 | lower the packed 6-bit scale unpack and the nibble dot pairs to SDOT with by-element scaling |
| `dbg_vec_dot_q6_K_q8_K` | q6_K x q8_K dot (Q4_K_M's q6_K tensors) | arm64 dotprod, amd64 avx2 | same as `dbg_vec_dot_q4_K_q8_K` |
| `dbg_flash_attn_kv_f16` | single-query flash-attention KV loop (F16 K/V: K.Q dot, online softmax, V accumulate) | arm64 fhm, arm64 neon, amd64 avx2 | fhm: blocks of eight positions, FMLAL K.Q, one vectorized expf per block, V accumulated in f16 registers (the native NEON path's VKQ16); neon/avx2: keep the per-position loop in registers (no per-position calls, an inline expf) |

## Layout

- `internal/asm/` — the generators (Go code that emits the assembly)
  and their tests. Each kernel has a numeric test against a float64
  reference over every length class it handles (vector body, tails,
  empty), executed on the host when it has the feature and assembled
  and linked everywhere.
- `cmd/genkernels/` — writes `asm/*.s`, `asm/overrides.json` and `asm/kernels.json`.
- `asm/` — the generated, checked-in output the build consumes
  (`WASM2GO_ASM_OVERRIDES` in the Makefile).

Regenerate after changing a generator:

```
cd kernels && go run ./cmd/genkernels -out asm
```

and run the tests:

```
cd kernels && go test ./...
```

The end-to-end check — the override bodies against wasm2go's own
lowering of the same exports — is go-llama's test suite against a bundle
built from this tree (its wikitext-2 perplexity parity and native-parity
tests), which runs before every release.
