# llama-wasm

[wasmify](https://github.com/goccy/wasmify) project that compiles
[llama.cpp](https://github.com/ggml-org/llama.cpp) to `wasm32-wasip1` and emits
the pure-Go ([wasm2go](https://github.com/goccy/wasm2go)) bindings
[go-llama](https://github.com/goccy/go-llama) consumes.

## Outputs

The CI workflow at `.github/workflows/build.yml` and the local `make wasm`
target both produce, from a clean checkout:

| File | Where | What |
| --- | --- | --- |
| `llama.wasm` | `.wasmify/wasm-build/output/llama.wasm` | The wasi-sdk-built llama.cpp — libllama plus the ggml CPU backend, behind the thin embedding API in `llama_api.h` — optimised by binaryen wasm-opt. |
| `llama_wasm2go.tar.gz` | `build/wasm2go/internal/wasm2go/` | The transpiled pure-Go bundle, a self-contained Go module (`github.com/goccy/llamawasm2go`). go-llama depends on it. |
| `llama_wasm2go.go` | `build/wasm2go/llama.go` | `protoc-gen-wasmify-go`'s wasm2go bridge. go-llama commits it as `llama.go`. |

Everything above is **regenerated** on every build; only the inputs below are
committed.

## Committed inputs

```
wasmify.json                # wasmify decisions: project metadata, build commands, bridge config
llama.cpp/                  # git submodule pinned to the upstream release we build against
buf.yaml                    # buf module
buf.gen.yaml                # protoc-gen-wasmify-go invocation (wasm2go bundle)
proto/wasmify/              # wasmify proto options the generated proto imports
llama_api.h, llama_api.cc   # the thin C++ embedding API
scripts/wasi-configure.sh   # CMake configure for wasm32-wasip1 (+ the EH runtimes)
scripts/build-eh-runtimes.sh# libunwind/libc++abi/libc++ rebuilt with wasm exception handling
scripts/allow-undefined.txt # the one symbol wasm-ld may leave undefined (the C++ exception tag)
scripts/run-smoke.sh, .js   # engine-only smoke test (no wasmify, no Go)
tests/smoke.cc              # what the smoke test exercises
```

## Why the C++ runtimes are rebuilt

llama.cpp throws: model loading raises `std::runtime_error` and the code catches
internally, so `-fno-exceptions` is not an option. wasi-sdk ships its C++
runtimes built *without* exception support, so linking `-fwasm-exceptions`
objects against them fails with undefined `__cxa_throw` / `__cpp_exception` /
`_Unwind_CallPersonality`. `scripts/build-eh-runtimes.sh` rebuilds libunwind,
libc++abi and libc++ from the LLVM release matching wasi-sdk's clang, with
exception handling on, into `deps/wasi-eh`. The result is cached by a version
stamp, so it is built once.

Wasm exception handling is a module-level feature: the archives, the bridge and
the runtimes must all agree. The flags live in three places that are kept in
sync deliberately — `scripts/wasi-configure.sh` (the llama.cpp build),
`wasmify.json`'s `wasm_build.extra_cxxflags` (the bridge), and
`scripts/run-smoke.sh` (the smoke test).

The linked wasm imports exactly one non-WASI symbol: the C++ exception tag
`env.__cpp_exception`. wasm2go provides it, so a Go consumer wires up nothing.

## Building locally

The full pipeline runs inside a wasmify image bundling wasi-sdk, binaryen, buf
and the wasmify CLI — you install none of those on your host:

```sh
make wasm                              # uses ghcr.io/goccy/wasmify:v0.4.10
make wasm DOCKER_PLATFORM=linux/amd64  # on Apple Silicon (the image is amd64-only)
make wasm LLAMA_THREADS=1              # wasm32-wasip1-threads build (multi-threaded ggml)
make wasm-clean                        # drop regenerated outputs, keep committed inputs
```

`make wasm` runs (under `docker run --rm -v $PWD:/work …`) the same sequence as
CI:

```
make tools                      # ensure wasi-sdk / cmake / ninja (pre-baked in the image)
scripts/wasi-configure.sh       # EH runtimes + CMake configure for wasm32-wasip1
wasmify build                   # replay the captured cmake build (libllama.a + ggml)
wasmify generate-build          # build.log -> build.json
wasmify parse-headers           # llama_api.h -> api-spec.json
wasmify gen-proto               # api-spec.json -> proto/ + bridge/
wasmify wasm-build --optimize   # build.json + bridge -> llama.wasm + wasm-opt
buf generate --timeout 0        # proto/ -> build/wasm2go/ (the wasm2go bundle)
make bundle-gomod               # stamp the bundle's go.mod
```

## Smoke test

`make smoke` builds `llama_api.cc` + `tests/smoke.cc` into a plain WASI command
with wasi-sdk and runs it under Node's WASI — no wasmify, no wasm2go, no Go. It
loads a tiny GGUF model (fetched on first run), tokenizes, generates, exercises
stop strings, streaming, state save, the chat template and every error path.
When something breaks after a llama.cpp bump, this says whether the engine layer
or the Go layer is at fault.

It needs the library built first:

```sh
bash scripts/wasi-configure.sh
cmake --build build-wasi --target llama --parallel 8
make smoke
```

## Memory limits

wasm32 caps linear memory at 4 GiB, and the model plus KV cache live inside it.
Target quantized models comfortably under that — roughly 3B parameters at Q4 —
and size the context accordingly.

## License

This repository's own sources are MIT (see LICENSE). llama.cpp is MIT; the
generated wasm and the wasm2go bundle are derivative works of it.
