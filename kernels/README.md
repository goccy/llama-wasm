# kernels — assembly bodies for the hot leaf functions

wasm2go lowers `llama.wasm` from the wasm itself. For a handful of leaf
compute kernels its lowering is still well short of what the CPU can
do, and this directory supplies those bodies by hand through wasm2go's
**assembly-override** mechanism (see `docs/asm-overrides.md` in
wasm2go): the wasm build exports each kernel under a `dbg_*` name (see
`patches/`), `asm/overrides.json` names the exports with their wasm
signatures, and `asm/*.s` hold one body per architecture and CPU
feature level. wasm2go validates the manifest against the module,
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
| `dbg_vec_dot_q5_0_q8_0` | q5_0 x q8_0 dot (the matmul of tensors K-quants cannot cover, e.g. Qwen2.5-0.5B's 896-wide rows) | arm64 dotprod | lower the fifth-bit gather + i16 dot pairs to CMTST/SDOT |
| `dbg_vec_dot_q4_K_q8_K` | q4_K x q8_K dot (Q4_K_M matmul) | arm64 dotprod | lower the packed 6-bit scale unpack and the nibble dot pairs to SDOT with by-element scaling |
| `dbg_vec_dot_q6_K_q8_K` | q6_K x q8_K dot (Q4_K_M's q6_K tensors) | arm64 dotprod | same as `dbg_vec_dot_q4_K_q8_K` |
| `dbg_flash_attn_kv_f16` | single-query flash-attention KV loop (F16 K/V: K.Q dot, online softmax, V accumulate) | arm64 neon | keep the per-position loop in registers (no per-position calls, an inline expf) |

## Layout

- `internal/asm/` — the generators (Go code that emits the assembly)
  and their tests. Each kernel has a numeric test against a float64
  reference over every length class it handles (vector body, tails,
  empty), executed on the host when it has the feature and assembled
  and linked everywhere.
- `cmd/genkernels/` — writes `asm/*.s` and `asm/overrides.json`.
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
