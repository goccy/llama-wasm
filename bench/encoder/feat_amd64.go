package main

import (
	"fmt"

	"github.com/goccy/llamawasm2go/base"
)

// features reports the bundle's amd64 dispatch decisions.
func features() string {
	return fmt.Sprintf("amd64 avx2=%v avx512vnni=%v", base.HasAVX2, base.HasAVX512VNNI)
}
