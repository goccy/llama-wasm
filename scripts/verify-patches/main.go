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
	// native-parity tests pin their output.
	"wasm-simd-vec-kernels.patch": {
		reason: "verified by go-llama's native-parity tests against the released bundle",
	},
	// Flash attention widens its K/V/mask tiles through the SIMD f16
	// loads and accumulates f16 V in f32 on wasm; same verification.
	"wasm-flash-attn-simd-widen.patch": {
		reason: "verified by go-llama's native-parity tests against the released bundle",
	},
	"wasm-q8-quantize-round-nearest.patch": {
		reason: "verified by go-llama's native-parity and prompt batch-invariance tests against the released bundle",
	},
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
