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
	// cpu_relax -> sched_yield: every ggml spin-wait must contain a call,
	// or it livelocks against the Go GC on the wasm2go host (a call-free
	// loop is lowered to assembly the runtime cannot async-preempt, so a
	// spinning worker blocks stop-the-world while the worker it waits for
	// stays parked). The artifact check is that no loop reaches its
	// back-branch having done an atomic load but no call.
	"wasm-spin-sched-yield.patch": {verify: verifyPreemptibleSpins},

	// The q8_0 repack kernels change numeric routing, not a structural
	// property this tool can read off the binary; their effect is pinned
	// by go-llama's repack numeric tests, which run against every
	// released bundle.
	"wasm-q8-repack-kernels.patch": {
		reason: "verified by go-llama's gemv repack numeric tests against the released bundle",
	},
}

func verifyPreemptibleSpins(wasm []byte) error {
	spins, err := scanBareSpins(wasm)
	if err != nil {
		return err
	}
	if len(spins) == 0 {
		return nil
	}
	var b strings.Builder
	fmt.Fprintf(&b, "%d bare atomic spin loop(s) — non-preemptible on the wasm2go host:\n", len(spins))
	for _, s := range spins {
		fmt.Fprintf(&b, "    %s\n", s)
	}
	b.WriteString("    was the patch compiled in, or did an upstream change add a spin site it does not reach?")
	return fmt.Errorf("%s", b.String())
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
