package asm

import (
	"fmt"
	"sort"
	"strings"
)

// ConstPool interns the constant blobs a body references, under the
// ovr_ prefix the assembly-override contract reserves for a body's own
// data, and renders them as DATA/GLOBL entries appended to the body.
type ConstPool struct {
	// prefix keeps one body's data symbols distinct from another's:
	// every body is its own assembly file in the same package, so two
	// bodies interning the same blob would otherwise define the same
	// GLOBL twice.
	prefix string
	blobs  map[string][]byte
}

// NewConstPool returns a pool whose symbols carry prefix after ovr_.
func NewConstPool(prefix string) *ConstPool {
	return &ConstPool{prefix: prefix}
}

// addBlob interns blob by content and returns the symbol to reference
// it by (as ·<name>(SB)).
func (p *ConstPool) addBlob(blob []byte) string {
	if p.blobs == nil {
		p.blobs = map[string][]byte{}
	}
	name := fmt.Sprintf("ovr_%sb%d_%x", p.prefix, len(blob), blob)
	p.blobs[name] = append([]byte(nil), blob...)
	return name
}

// Emit renders the pool's DATA/GLOBL trailer in a deterministic order.
func (p *ConstPool) Emit() string {
	names := make([]string, 0, len(p.blobs))
	for n := range p.blobs {
		names = append(names, n)
	}
	sort.Strings(names)
	var b strings.Builder
	for _, n := range names {
		blob := p.blobs[n]
		for off := 0; off < len(blob); off += 8 {
			end := off + 8
			if end > len(blob) {
				end = len(blob)
			}
			var v uint64
			for i := end - 1; i >= off; i-- {
				v = v<<8 | uint64(blob[i])
			}
			fmt.Fprintf(&b, "DATA ·%s+%d(SB)/%d, $0x%x\n", n, off, end-off, v)
		}
		fmt.Fprintf(&b, "GLOBL ·%s(SB), RODATA|NOPTR, $%d\n", n, len(blob))
	}
	return b.String()
}
