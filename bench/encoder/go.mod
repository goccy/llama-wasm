module github.com/goccy/llama-wasm/bench/encoder

go 1.25.0

require github.com/goccy/go-llama v0.5.1

require github.com/goccy/llamawasm2go v0.4.1 // indirect

// The bundle under test: build/wasm2go/internal/wasm2go after `make wasm`
// (or the extracted llama_wasm2go.tar.gz of a CI build).
replace github.com/goccy/llamawasm2go => ../../build/wasm2go/internal/wasm2go
