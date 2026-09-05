// verify-patches proves the built llama.wasm reflects every source patch
// scripts/wasi-configure.sh applies.
//
// Applying a patch and compiling it are different events: a stale object
// cache once shipped a release whose build log printed "applied patch"
// while the artifact was compiled from unpatched sources. The artifact is
// the only evidence that counts, so every file in patches/ must register
// here either an artifact-level check or an explicit exemption naming
// where the patch's effect is verified instead. An unregistered patch
// fails the run — adding a patch without deciding how it is verified is
// itself the error this tool exists to catch.
//
// Usage: verify-patches -wasm <llama.wasm> -patches <patches-dir>
package main

import (
	"bytes"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"sort"
)

// verification is what a patch registers: an artifact check over the built
// wasm, or (verify == nil) an exemption whose reason names the place the
// patch's effect is verified instead.
type verification struct {
	verify func(wasm []byte) error
	reason string
}

var registry = map[string]verification{
	// The q8_0 repack kernels change numeric routing, not a structural
	// property this tool can read off the binary; their effect is pinned
	// by go-llama's repack numeric tests, which run against every
	// released bundle.
	"wasm-q8-repack-kernels.patch": {
		reason: "verified by go-llama's gemv repack numeric tests against the released bundle",
	},
	// Rounding inside the wasm q8_0 activation quantizers is a numeric
	// property, not a structural one; go-llama's native-parity and
	// batch-invariance tests pin it against the released bundle.
	// The vector expf/silu/soft_max/max paths and the f16 widening
	// idioms are numeric replacements of scalar loops; go-llama's
	// native-parity tests pin their output. The dbg_* exports the patch
	// adds (soft_max, swiglu, the f16 dot and the f16 multiply-add) are
	// the transpiler's kernel-retarget hooks; go-llama's tests run
	// through them on every released bundle.
	"wasm-simd-vec-kernels.patch": {
		reason: "verified by go-llama's native-parity tests against the released bundle",
	},
	// Flash attention widens its K/V/mask tiles through the SIMD f16
	// loads and accumulates f16 V in f32 on wasm; same verification.
	"wasm-flash-attn-simd-widen.patch": {
		reason: "verified by go-llama's native-parity tests against the released bundle",
	},
	"wasm-legacy-vec-dot-q4-1-q5-1-kernels.patch": {
		verify: hasExports("dbg_vec_dot_q4_1_q8_1", "dbg_vec_dot_q5_1_q8_1"),
	},
	"wasm-q8-quantize-round-nearest.patch": {
		reason: "verified by go-llama's native-parity and prompt batch-invariance tests against the released bundle",
	},
	// The K-quant / q5_0 vec_dot exports are structural: the export
	// names must be present in the binary for wasm2go's assembly
	// overrides (kernels/) to attach; a module without them silently
	// runs the transpiled bodies instead.
	"wasm-iq4-nl-kernels.patch": {
		verify: hasExports("dbg_gemv_iq4_nl_8x8", "dbg_gemm_iq4_nl_8x8", "dbg_vec_dot_iq4_nl_q8_0"),
	},
	"wasm-kquant-vec-dot-kernels.patch": {
		verify: hasExports("dbg_vec_dot_q5_0_q8_0", "dbg_vec_dot_q4_K_q8_K", "dbg_vec_dot_q6_K_q8_K"),
	},
	// The flash-attention KV loop export is structural in the same way.
	"wasm-flash-attn-kv-loop-export.patch": {
		verify: hasExports("dbg_flash_attn_kv_f16"),
	},
	// The Q4_K 8x8 repack GEMV/GEMM exports (applied after the q8_0 repack
	// patch that creates arch/wasm/repack.cpp).
	"wasm-kquant-vec-dot-q2k-q3k-q5k-kernels.patch": {
		verify: hasExports("dbg_vec_dot_q2_K_q8_K", "dbg_vec_dot_q3_K_q8_K", "dbg_vec_dot_q5_K_q8_K"),
	},
	"wasm-q8-repack-q4-0-kernels.patch": {
		verify: hasExports("dbg_gemv_q4_0_8x8", "dbg_gemm_q4_0_8x8"),
	},
	"wasm-q8-repack-q4k-kernels.patch": {
		verify: hasExports("dbg_gemv_q4_K_8x8", "dbg_gemm_q4_K_8x8"),
	},
	// The q8_Kx4 activation quantizer export (the repack GEMM's input).
	"wasm-q8k-quantize-mat-export.patch": {
		verify: hasExports("dbg_quantize_mat_q8_K_4x8"),
	},
	// The Q5_0 8x8 repack (block_q5_0x8, its GEMV/GEMM and the q8_0x4
	// activation quantizer the GEMM consumes).
	"wasm-vec-dot-q4-0-q8-0-kernels.patch": {
		verify: hasExports("dbg_vec_dot_q4_0_q8_0", "dbg_vec_dot_q8_0_q8_0"),
	},
	"wasm-q8-repack-q5k-kernels.patch": {
		verify: hasExports("dbg_gemv_q5_K_8x8", "dbg_gemm_q5_K_8x8"),
	},
	"wasm-q8-repack-q6k-kernels.patch": {
		verify: hasExports("dbg_gemv_q6_K_8x8", "dbg_gemm_q6_K_8x8"),
	},
	"wasm-q8-repack-q5-0-kernels.patch": {
		verify: hasExports("dbg_gemv_q5_0_8x8", "dbg_gemm_q5_0_8x8", "dbg_quantize_mat_q8_0_4x8"),
	},
}

// hasExports checks that every name appears in the module's export
// section. Export names are stored as length-prefixed UTF-8 in the
// binary, so a missing byte string is a missing export; a present one
// is accepted without decoding the section (nothing else in the module
// carries a dbg_-prefixed name).
func hasExports(names ...string) func([]byte) error {
	return func(wasm []byte) error {
		for _, n := range names {
			if !bytes.Contains(wasm, []byte(n)) {
				return fmt.Errorf("export %q not found in the module", n)
			}
		}
		return nil
	}
}

func run() error {
	wasmPath := flag.String("wasm", "", "built wasm module to verify")
	patchesDir := flag.String("patches", "", "directory of the applied patches")
	flag.Parse()
	if *wasmPath == "" || *patchesDir == "" {
		return fmt.Errorf("both -wasm and -patches are required")
	}

	wasm, err := os.ReadFile(*wasmPath)
	if err != nil {
		return err
	}
	patches, err := filepath.Glob(filepath.Join(*patchesDir, "*.patch"))
	if err != nil {
		return err
	}
	if len(patches) == 0 {
		return fmt.Errorf("no *.patch files under %s — wrong -patches directory?", *patchesDir)
	}
	sort.Strings(patches)

	failures := 0
	for _, p := range patches {
		name := filepath.Base(p)
		v, ok := registry[name]
		switch {
		case !ok:
			failures++
			fmt.Printf("FAIL %s: no verification registered — add an artifact check "+
				"(or an explicit exemption naming where it is verified) to scripts/verify-patches\n", name)
		case v.verify == nil:
			fmt.Printf("ok   %s (exempt: %s)\n", name, v.reason)
		default:
			if err := v.verify(wasm); err != nil {
				failures++
				fmt.Printf("FAIL %s: %v\n", name, err)
			} else {
				fmt.Printf("ok   %s\n", name)
			}
		}
	}
	for name := range registry {
		if !slicesContainsBase(patches, name) {
			failures++
			fmt.Printf("FAIL %s: registered here but missing from %s — remove the stale entry\n",
				name, *patchesDir)
		}
	}
	if failures > 0 {
		return fmt.Errorf("%d patch verification(s) failed", failures)
	}
	return nil
}

func slicesContainsBase(paths []string, base string) bool {
	for _, p := range paths {
		if filepath.Base(p) == base {
			return true
		}
	}
	return false
}

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, "verify-patches:", err)
		os.Exit(1)
	}
}
