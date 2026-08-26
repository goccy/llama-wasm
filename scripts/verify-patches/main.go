// verify-patches proves the built artifacts reflect the project's source
// patches and the toolchain invariants they rely on.
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
// Beyond the patches, one toolchain invariant is checked when -bundle is
// given: the wasm legitimately contains bare atomic spin loops
// (ggml_barrier's waits — no guest patch touches them any more), and the
// wasm2go transpiler inside the pinned wasmify image is responsible for
// guarding every one of them with a preemption point. A bundle emitted
// without those guards livelocks the Go GC under load, so an image bump
// to a transpiler that lost the guard must fail here, not in production.
//
// Usage: verify-patches -wasm <llama.wasm> -patches <patches-dir> [-bundle <dir>]
package main

import (
	"bytes"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
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
}

// verifyBundleSpinGuards is the toolchain-invariant check behind
// -bundle: when the wasm contains bare atomic spin loops (it does — the
// former guest-side sched-yield patch is gone by design), the wasm2go
// transpiler must have planted its preemption guards in the emitted
// bundle. The marker is the guard counter the emitters declare next to
// every guarded loop; its absence means the pinned image transpiles
// spin loops the Go runtime cannot preempt after asm capture.
func verifyBundleSpinGuards(wasm []byte, bundleDir string) error {
	spins, err := scanBareSpins(wasm)
	if err != nil {
		return err
	}
	if len(spins) == 0 {
		// Nothing to guard: the invariant holds vacuously.
		return nil
	}
	guarded := 0
	err = filepath.WalkDir(bundleDir, func(p string, d os.DirEntry, err error) error {
		if err != nil || d.IsDir() || !strings.HasSuffix(p, ".go") {
			return err
		}
		data, err := os.ReadFile(p)
		if err != nil {
			return err
		}
		guarded += bytes.Count(data, []byte("__spinGuard"))
		return nil
	})
	if err != nil {
		return err
	}
	if guarded == 0 {
		return fmt.Errorf("the wasm has %d bare atomic spin loop(s) but the bundle carries no spin guards — "+
			"the pinned wasmify image's wasm2go does not guard bare spins (needs >= v0.5.7); "+
			"such a bundle livelocks the Go GC under multi-threaded load", len(spins))
	}
	fmt.Printf("ok   transpiler spin guards (%d bare wasm spin loops, %d guard markers in the bundle)\n",
		len(spins), guarded)
	return nil
}

func run() error {
	wasmPath := flag.String("wasm", "", "built wasm module to verify")
	patchesDir := flag.String("patches", "", "directory of the applied patches")
	bundleDir := flag.String("bundle", "", "emitted wasm2go bundle to check the transpiler spin guards in (empty skips the check)")
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
	if *bundleDir != "" {
		if err := verifyBundleSpinGuards(wasm, *bundleDir); err != nil {
			failures++
			fmt.Printf("FAIL transpiler spin guards: %v\n", err)
		}
	} else {
		fmt.Println("note transpiler spin-guard check skipped (no -bundle)")
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
