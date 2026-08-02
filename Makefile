# Container image shipping every toolchain wasmify needs (wasi-sdk + binaryen +
# buf + the wasmify CLI itself). Override locally to pin a SHA or to iterate on a
# wasmify branch — e.g. `make wasm IMAGE=localhost:5001/wasmify:local`.
IMAGE ?= ghcr.io/goccy/wasmify:v0.4.10

# Resource limits for the container that runs the pipeline. A full llama.cpp +
# ggml wasm build peaks well under MEMORY; CPUS bounds the build's parallelism.
MEMORY ?= 10g
CPUS   ?= 8

# The wasmify image is published linux/amd64 only. On an arm64 host (Apple
# Silicon) set DOCKER_PLATFORM=linux/amd64 to run it under emulation:
#   make wasm DOCKER_PLATFORM=linux/amd64
DOCKER_PLATFORM ?=
PLATFORM_FLAG := $(if $(DOCKER_PLATFORM),--platform=$(DOCKER_PLATFORM),)

# Bundle module path / go directive stamped into the wasm2go bundle's go.mod.
# The bundle is released as a self-contained Go module, so it needs a go.mod
# declaring the import path its own `import` / `//go:linkname` sites embed.
# wasmify writes that path into wasmify.json's bridge.Wasm2GoImportPath, which
# the codegen reads back; derive it from the JSON so the two never drift.
WASM2GO_BUNDLE_DIR    := build/wasm2go/internal/wasm2go
WASM2GO_BUNDLE_GO_VER := 1.25.0

# Set LLAMA_THREADS=1 to configure the wasm32-wasip1-threads build, which lets
# ggml run its kernels on several threads (wasm2go runs each guest thread on a
# goroutine, so no host work is needed). The default single-threaded build has
# no pthread_create, so a context must use n_threads=1.
LLAMA_THREADS ?= 0

BUILD_ENV = WASMIFY_NON_INTERACTIVE=1 LLAMA_THREADS=$(LLAMA_THREADS)

# Full pipeline replayed inside the container, top-to-bottom.
#
# The configure phase does two things wasmify cannot: it primes the CMake cache
# for wasm32-wasip1, and it builds the C++ runtimes with wasm exception handling
# (llama.cpp throws, and wasi-sdk's stock libc++abi has no EH). `wasmify build`
# then replays the captured cmake build under the compiler wrapper;
# generate-build emits build.json, parse-headers/gen-proto emit the api spec +
# proto + bridge, wasm-build links llama.wasm (llama_api.cc is injected as a
# CustomBridgeSource), and buf generate + bundle-gomod produce the wasm2go
# bundle as a self-contained Go module.
WASMIFY_PIPELINE = \
	make tools && \
	$(BUILD_ENV) bash scripts/wasi-configure.sh && \
	$(BUILD_ENV) wasmify build --non-interactive && \
	wasmify generate-build && \
	wasmify parse-headers --header llama_api.h && \
	wasmify gen-proto && \
	$(BUILD_ENV) wasmify wasm-build --optimize --non-interactive && \
	rm -rf build && \
	buf generate --timeout 0 && \
	make bundle-gomod
# `rm -rf build` so `buf generate` writes the wasm2go bundle into a CLEAN tree:
# protoc-gen-wasmify-go overwrites the files it emits but never deletes stale
# ones, and the bundle's file SET depends on the wasm's size (a sub-threshold
# wasm yields a single-package layout; a larger one yields the base/ + pN
# multi-package layout). Mixing two leftover sets in one package won't compile.
#
# `buf generate --timeout 0`: buf's default two-minute plugin timeout SIGKILLs
# protoc-gen-wasmify-go mid-transpile on a wasm this size and reports only
# "signal: killed".

.PHONY: all wasm wasm-clean tools bundle-gomod smoke image-pull help

all: wasm

# Install the tools wasmify.json declares (wasi-sdk, cmake, ninja; pre-baked in
# the image). Safe to re-run; already-installed tools are skipped.
tools:
	wasmify ensure-tools ./llama.cpp --output-dir .

# Build llama.wasm + the wasm2go bundle from a clean checkout, exactly the way
# .github/workflows/build.yml does. Outputs:
#   .wasmify/wasm-build/output/llama.wasm
#   build/wasm2go/                                <- wasm2go bridge + bundle
#   build/wasm2go/internal/wasm2go/go.mod         <- bundle module manifest
wasm:
	docker run --rm $(PLATFORM_FLAG) \
		-v $(CURDIR):/work -w /work \
		--memory=$(MEMORY) --cpus=$(CPUS) \
		-e WASMIFY_NON_INTERACTIVE=1 \
		$(IMAGE) \
		bash -c '$(WASMIFY_PIPELINE)'

# Build and run the bridge smoke test: llama_api.cc plus a plain WASI main,
# linked with wasi-sdk and run under a wasm runtime — no wasmify, no wasm2go,
# no Go. When something breaks after a llama.cpp bump, this says whether the
# engine layer or the Go layer is at fault. Needs a GGUF model; a tiny one is
# fetched on first run.
smoke:
	bash scripts/run-smoke.sh

# Write go.mod into the wasm2go bundle so the released tarball is a
# self-contained Go module. Parses bridge.Wasm2GoImportPath out of wasmify.json
# with grep+sed (no jq in the image; no Go toolchain needed — a literal manifest).
bundle-gomod:
	@if [ ! -d "$(WASM2GO_BUNDLE_DIR)" ]; then \
		echo "$(WASM2GO_BUNDLE_DIR) does not exist — run 'make wasm' first" >&2; \
		exit 1; \
	fi
	@path=$$(grep -E '"Wasm2GoImportPath"[[:space:]]*:' wasmify.json \
		| head -1 \
		| sed -E 's/.*"Wasm2GoImportPath"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/'); \
	if [ -z "$$path" ]; then \
		echo "wasmify.json bridge.Wasm2GoImportPath is empty; cannot stamp bundle go.mod" >&2; \
		exit 1; \
	fi; \
	printf 'module %s\n\ngo %s\n' "$$path" "$(WASM2GO_BUNDLE_GO_VER)" \
		> $(WASM2GO_BUNDLE_DIR)/go.mod; \
	echo "wrote $(WASM2GO_BUNDLE_DIR)/go.mod (module $$path)"

# Drop everything wasmify regenerates so the next `make wasm` runs from scratch.
# The committed inputs (wasmify.json, buf.{yaml,gen.yaml}, proto/wasmify,
# llama_api.{h,cc}, scripts/, the llama.cpp submodule) survive, and so does
# deps/ — the EH runtimes are a pure function of the wasi-sdk version and cost
# several minutes to rebuild. Use `make deps-clean` to drop those too.
wasm-clean:
	rm -rf .wasmify api-spec.json build.json proto/llama.proto bridge build build-wasi

deps-clean:
	rm -rf deps

# Refresh the cached toolchain image.
image-pull:
	docker pull $(PLATFORM_FLAG) $(IMAGE)

help:
	@echo 'Targets:'
	@echo '  wasm         Build llama.wasm + wasm2go bundle inside $(IMAGE)'
	@echo '  smoke        Build and run the bridge smoke test (no Go involved)'
	@echo '  wasm-clean   Drop generated artefacts; keep committed inputs and deps/'
	@echo '  deps-clean   Drop deps/ (the EH-enabled C++ runtimes)'
	@echo '  image-pull   docker pull $(IMAGE)'
	@echo ''
	@echo 'Variables:'
	@echo '  IMAGE           = $(IMAGE)'
	@echo '  MEMORY          = $(MEMORY)'
	@echo '  CPUS            = $(CPUS)'
	@echo '  LLAMA_THREADS   = $(LLAMA_THREADS)   (1 = wasm32-wasip1-threads build)'
	@echo '  DOCKER_PLATFORM = $(DOCKER_PLATFORM)   (set to linux/amd64 on arm64 hosts)'
