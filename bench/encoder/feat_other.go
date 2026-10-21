//go:build !amd64

package main

import "runtime"

func features() string { return runtime.GOARCH }
