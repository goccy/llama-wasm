// genkernels writes the assembly-override bodies and manifest that
// llama-wasm hands to wasm2go (docs/asm-overrides.md there): one
// assembly file per export, architecture and CPU feature level, plus
// overrides.json describing the exports' wasm signatures.
//
//	go run ./cmd/genkernels -out ../asm
//
// The exports are the dbg_* functions the wasm build exposes for this
// purpose (see patches/); the bodies come from internal/asm.
package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"path/filepath"

	"github.com/goccy/llama-wasm/kernels/internal/asm"
)

func main() {
	out := flag.String("out", "asm", "output directory for the bodies and overrides.json")
	flag.Parse()
	if err := run(*out); err != nil {
		fmt.Fprintln(os.Stderr, "genkernels:", err)
		os.Exit(1)
	}
}

func run(out string) error {
	if err := os.MkdirAll(out, 0o755); err != nil {
		return err
	}
	man := asm.Overrides()
	for _, k := range man.Kernels {
		for i := range k.Bodies {
			b := &k.Bodies[i]
			name := fmt.Sprintf("%s_%s_%s.s", k.Export, b.Arch, b.Feature)
			if err := os.WriteFile(filepath.Join(out, name), []byte(b.Text), 0o644); err != nil {
				return err
			}
			b.File = name
		}
	}
	data, err := json.MarshalIndent(man, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(filepath.Join(out, "overrides.json"), append(data, '\n'), 0o644)
}
