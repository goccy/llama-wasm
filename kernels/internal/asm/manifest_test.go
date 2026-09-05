package asm

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
)

// TestManifestKernelIndex: every override names what it computes and for
// which tensor type, the index the bundle embeds derives from it, and the
// checked-in asm/kernels.json is what the current manifest produces.
func TestManifestKernelIndex(t *testing.T) {
	man := Overrides()
	valid := map[Role]bool{RoleGemv: true, RoleGemm: true, RoleVecDot: true, RoleQuantizeMat: true, RoleOp: true}
	for _, k := range man.Kernels {
		if !valid[k.Role] {
			t.Errorf("%s: role %q is not a known Role", k.Export, k.Role)
		}
		if k.Quant == "" {
			t.Errorf("%s: no tensor type", k.Export)
		}
		if len(k.Bodies) == 0 {
			t.Errorf("%s: no bodies", k.Export)
		}
	}
	idx := man.Index()
	if len(idx.Kernels) != len(man.Kernels) {
		t.Fatalf("index has %d kernels, manifest %d", len(idx.Kernels), len(man.Kernels))
	}
	byExport := map[string]IndexedKernel{}
	for _, k := range idx.Kernels {
		byExport[k.Export] = k
	}
	for _, k := range man.Kernels {
		got := byExport[k.Export]
		if got.Role != k.Role || got.Quant != k.Quant {
			t.Errorf("%s: index says %s/%s, manifest %s/%s", k.Export, got.Role, got.Quant, k.Role, k.Quant)
		}
		for _, b := range k.Bodies {
			found := false
			for _, a := range got.Arches {
				found = found || a == b.Arch
			}
			if !found {
				t.Errorf("%s: index lacks arch %s", k.Export, b.Arch)
			}
		}
	}
	want, err := json.MarshalIndent(idx, "", "  ")
	if err != nil {
		t.Fatal(err)
	}
	have, err := os.ReadFile(filepath.Join("..", "..", "asm", "kernels.json"))
	if err != nil {
		t.Fatal(err)
	}
	if string(have) != string(want)+"\n" {
		t.Fatalf("asm/kernels.json is stale: run `cd kernels && go run ./cmd/genkernels -out asm`")
	}
}
