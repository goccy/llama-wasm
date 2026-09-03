# Container image shipping every toolchain wasmify needs (wasi-sdk + binaryen +
# buf + the wasmify CLI itself). Override locally to pin a SHA or to iterate on a
# wasmify branch — e.g. `make wasm IMAGE=localhost:5001/wasmify:local`.
IMAGE ?= ghcr.io/goccy/wasmify:v0.6.14

# Resource limits for the container that runs the pipeline. A full llama.cpp +
# ggml wasm build peaks well under MEMORY; CPUS bounds the build's parallelism.
MEMORY ?= 10g
CPUS   ?= 8

# Container runtime. Apple's `container` is the default on macOS (it runs Linux
# images natively on Apple Silicon without Docker Desktop); everywhere else the
# default is docker. Override to pick another: `make wasm CONTAINER=podman`.
ifeq ($(shell uname -s),Darwin)
CONTAINER ?= $(shell command -v container 2>/dev/null || echo docker)
else
CONTAINER ?= docker
endif

# The wasmify image is published linux/amd64 only, so an Apple Silicon host runs
# it emulated and needs the platform spelled out. `uname -m` is not a reliable
# probe on macOS — a shell started under Rosetta reports x86_64 on an arm64
# machine — so ask sysctl instead. Set CONTAINER_PLATFORM= (empty) to let the
# runtime choose.
ifeq ($(shell uname -s),Darwin)
HOST_IS_ARM64 := $(shell sysctl -n hw.optional.arm64 2>/dev/null)
else
HOST_IS_ARM64 := $(if $(filter aarch64 arm64,$(shell uname -m)),1,)
endif
ifeq ($(HOST_IS_ARM64),1)
CONTAINER_PLATFORM ?= linux/amd64
else
CONTAINER_PLATFORM ?=
endif
PLATFORM_FLAG := $(if $(CONTAINER_PLATFORM),--platform=$(CONTAINER_PLATFORM),)

# Bundle module path / go directive stamped into the wasm2go bundle's go.mod.
# The bundle is released as a self-contained Go module, so it needs a go.mod
# declaring the import path its own `import` / `//go:linkname` sites embed.
# wasmify writes that path into wasmify.json's bridge.Wasm2GoImportPath, which
# the codegen reads back; derive it from the JSON so the two never drift.
WASM2GO_BUNDLE_DIR    := build/wasm2go/internal/wasm2go
WASM2GO_BUNDLE_GO_VER := 1.25.0

# WASMIFY_SRC / WASM2GO_SRC point at local checkouts to build and use INSTEAD
# of the CLI and transpiler baked into the image — the way to test a fix in
# either before it is released:
#   make wasm WASMIFY_SRC=../wasmify WASM2GO_SRC=../wasm2go
# Empty (the default) uses the image's own binaries.
WASMIFY_SRC ?=
WASM2GO_SRC ?=

ifneq ($(WASMIFY_SRC),)
WASMIFY_SRC_MOUNT := -v $(abspath $(WASMIFY_SRC)):/wasmify-src
# A local wasm2go is wired in with a go.mod replace inside the container, so
# the plugin links the checkout rather than the pinned release. `go mod edit`
# writes to the mounted source, so undo it on the way out.
ifneq ($(WASM2GO_SRC),)
WASM2GO_SRC_MOUNT := -v $(abspath $(WASM2GO_SRC)):/wasm2go-src
WASM2GO_REPLACE   := go mod edit -replace github.com/goccy/wasm2go=/wasm2go-src &&
WASM2GO_UNREPLACE := ; cd /wasmify-src && go mod edit -dropreplace github.com/goccy/wasm2go; cd /work
else
WASM2GO_SRC_MOUNT :=
WASM2GO_REPLACE   :=
WASM2GO_UNREPLACE :=
endif
WASMIFY_BUILD_STEP := cd /wasmify-src && $(WASM2GO_REPLACE) go build -o /usr/local/bin/wasmify ./cmd/wasmify && go build -o /usr/local/bin/protoc-gen-wasmify-go ./protoc-plugins/protoc-gen-wasmify-go && cd /work &&
else
WASMIFY_SRC_MOUNT :=
WASM2GO_SRC_MOUNT :=
WASMIFY_BUILD_STEP :=
WASM2GO_UNREPLACE :=
endif

# LLAMA_THREADS selects the -threads priming build (real pthreads; wasm2go
# runs each guest thread on a goroutine). It defaults to wasmify.json's
# bridge.HostThreads so the priming build and the wasmify replay always agree
# on the thread model; override on the make command line to experiment.
LLAMA_THREADS ?= $(shell grep -q '"HostThreads": true' wasmify.json && echo 1 || echo 0)

BUILD_ENV = WASMIFY_NON_INTERACTIVE=1 LLAMA_THREADS=$(LLAMA_THREADS)

# parse-headers runs clang over llama_api.h with the flags the build captured,
# which include the wasm target and the EH-runtime include path. A host clang
# cannot make sense of those (it rejects wasm builtins and cannot find the wasi
# sysroot), so point it at wasi-sdk's clang — the same compiler that built the
# archives.
WASI_CLANG = $${WASI_SDK_PATH:-$$HOME/.config/wasmify/bin/wasi-sdk}/bin/clang

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
	$(WASMIFY_BUILD_STEP) \
	make tools && \
	$(BUILD_ENV) bash scripts/wasi-configure.sh && \
	$(BUILD_ENV) wasmify build --non-interactive && \
	wasmify generate-build && \
	wasmify parse-headers --header llama_api.h --clang $(WASI_CLANG) && \
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

.PHONY: all wasm wasm-clean deps-clean tools bundle-gomod link-check-bundle smoke verify-patches shell image-pull help

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
# Transpiler tuning for the wasm2go bundle. These reach the
# protoc-gen-wasmify-go transpile step through the container
# environment; they match the measured production configuration.
# Override on the make command line to build variants (e.g.
# WASM2GO_FAST_MATH=). The f16 table address needs no configuration:
# wasm2go auto-detects it from the engine's own init loop and FAILS
# the transpile when gather sites cannot be verified (the v0.2.1
# release shipped ~35% slower decode from a stale manual address —
# that class of input no longer exists).
# The outlining threshold is width-dependent: memory64 modules carry
# i64 locals that double the packed-boundary round-trip cost, and the
# measured optimum moves from 100 (wasm32) to 400 (wasm64) — tg +12%
# at equal pp on the qwen2.5 q8_0 bench.
WASM2GO_OUTLINE ?= $(shell grep -q '"wasm64": true' wasmify.json && echo 400 || echo 100)
# The canonical tuning set, as VAR=value pairs. `make wasm` turns it
# into docker -e flags; `make print-wasm2go-env` prints it as shell
# export lines for consumers that run the pipeline steps directly
# (CI's docker exec) so both paths transpile with the same values.
WASM2GO_TUNING = \
	WASM2GO_OUTLINE=$(WASM2GO_OUTLINE) \
	WASM2GO_UNROLL=4 \
	WASM2GO_FUSE_LOOP=1 \
	WASM2GO_FUSE_LOOP_UNROLL=4 \
	WASM2GO_FAST_MATH=$(WASM2GO_FAST_MATH) \
	WASM2GO_ASM_OVERRIDES=$(WASM2GO_ASM_OVERRIDES)
WASM2GO_ENV ?= $(addprefix -e ,$(WASM2GO_TUNING))
WASM2GO_FAST_MATH ?= 1
# The assembly-override manifest (wasm2go -asm-overrides): the bodies
# kernels/ generates for the dbg_* exports, wrapped by wasm2go in its
# override ABI and dispatched on CPU features. Empty transpiles every
# export from the wasm. Regenerate with `cd kernels && go run
# ./cmd/genkernels -out asm` after changing a generator.
WASM2GO_ASM_OVERRIDES ?= kernels/asm/overrides.json

print-wasm2go-env:
	@for v in $(WASM2GO_TUNING); do echo "export $$v"; done

wasm:
	$(CONTAINER) run --rm $(PLATFORM_FLAG) \
		-v $(CURDIR):/work $(WASMIFY_SRC_MOUNT) $(WASM2GO_SRC_MOUNT) -w /work \
		--memory=$(MEMORY) --cpus=$(CPUS) \
		-e WASMIFY_NON_INTERACTIVE=1 $(WASM2GO_ENV) \
		$(IMAGE) \
		bash -c '$(WASMIFY_PIPELINE)$(WASM2GO_UNREPLACE)'

# Build and run the bridge smoke test: llama_api.cc plus a plain WASI main,
# linked with wasi-sdk and run under a wasm runtime — no wasmify, no wasm2go,
# no Go. When something breaks after a llama.cpp bump, this says whether the
# engine layer or the Go layer is at fault. Needs a GGUF model; a tiny one is
# fetched on first run.
smoke:
	bash scripts/run-smoke.sh

# Prove the built wasm reflects every patch scripts/wasi-configure.sh
# applies. "applied patch" in a build log is not evidence — a stale object
# cache once shipped a release compiled from unpatched sources — so every
# patches/*.patch must register an artifact-level check (or an explicit,
# reasoned exemption) in scripts/verify-patches, and an unregistered patch
# fails the run. Pure Go over the wasm binary, no external tooling; CI
# calls exactly this target, and it audits any module directly, e.g. a
# downloaded release asset:
#   make verify-patches WASM_OUTPUT=llama.wasm
WASM_OUTPUT ?= .wasmify/wasm-build/output/llama.wasm

verify-patches:
	go -C scripts/verify-patches run . \
		-wasm $(abspath $(WASM_OUTPUT)) -patches $(CURDIR)/patches

# Write go.mod into the wasm2go bundle so the released tarball is a
# self-contained Go module. Parses bridge.Wasm2GoImportPath out of wasmify.json
# with grep+sed (no jq in the image; no Go toolchain needed — a literal manifest).
# Link a consumer binary against the generated wasm2go bundle for every
# asm target (linux/arm64, linux/amd64 v2, linux/amd64 v1) before it is
# published. Compiling the bundle's packages does not run the linker's
# nosplit / ABI-wrapper resolution: v0.3.1 shipped a bundle that compiled
# everywhere and failed to link on both asm targets, and the failure
# surfaced only in a downstream consumer four releases later. Runs
# host-direct (needs Go, not the container); cross-compiles, nothing runs.
link-check-bundle:
	@test -f "$(WASM2GO_BUNDLE_DIR)/go.mod" \
		|| { echo "$(WASM2GO_BUNDLE_DIR)/go.mod missing — run 'make wasm' (bundle-gomod) first" >&2; exit 1; }
	@set -eu; dir=$$(mktemp -d); trap 'rm -rf $$dir' EXIT; \
	scripts/bundle-link-consumer.sh "$(abspath $(WASM2GO_BUNDLE_DIR))" \
		"$$(awk '/^module /{print $$2}' $(WASM2GO_BUNDLE_DIR)/go.mod)" "$$dir"

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

# Refresh the cached toolchain image. Apple's `container` nests pull under
# `image`; docker and podman take it at the top level.
PULL_CMD := $(if $(filter %container,$(CONTAINER)),$(CONTAINER) image pull,$(CONTAINER) pull)

image-pull:
	$(PULL_CMD) $(PLATFORM_FLAG) $(IMAGE)

# Open a shell in the toolchain image with the project mounted — the way to
# debug a pipeline phase that fails only inside the container.
shell:
	$(CONTAINER) run --rm -it $(PLATFORM_FLAG) \
		-v $(CURDIR):/work -w /work \
		--memory=$(MEMORY) --cpus=$(CPUS) \
		-e WASMIFY_NON_INTERACTIVE=1 \
		$(IMAGE) bash

help:
	@echo 'Targets:'
	@echo '  wasm         Build llama.wasm + wasm2go bundle inside $(IMAGE)'
	@echo '  smoke        Build and run the bridge smoke test (no Go involved)'
	@echo '  verify-patches  Check the built wasm reflects every patches/*.patch'
	@echo '  wasm-clean   Drop generated artefacts; keep committed inputs and deps/'
	@echo '  deps-clean   Drop deps/ (the EH-enabled C++ runtimes)'
	@echo '  shell        Interactive shell in $(IMAGE) with the project mounted'
	@echo '  image-pull   $(PULL_CMD) $(IMAGE)'
	@echo ''
	@echo 'Variables:'
	@echo '  IMAGE              = $(IMAGE)'
	@echo '  CONTAINER          = $(CONTAINER)'
	@echo '  CONTAINER_PLATFORM = $(CONTAINER_PLATFORM)'
	@echo '  MEMORY             = $(MEMORY)'
	@echo '  CPUS               = $(CPUS)'
	@echo '  LLAMA_THREADS      = $(LLAMA_THREADS)   (1 = wasm32-wasip1-threads build)'
	@echo '  WASMIFY_SRC        = $(WASMIFY_SRC)   (path to a wasmify checkout to build and use)'
	@echo '  WASM2GO_SRC        = $(WASM2GO_SRC)   (path to a wasm2go checkout; needs WASMIFY_SRC)'
