#!/bin/bash
# run-smoke.sh — build and run the bridge smoke test.
#
# Compiles llama_api.cc plus tests/smoke.cc into a plain WASI command with
# wasi-sdk and runs it under a wasm runtime. No wasmify, no wasm2go, no Go:
# when something breaks after a llama.cpp bump, this says whether the engine
# layer or the Go layer is at fault.
#
# The flags below are a hand-maintained mirror of wasmify.json's
# wasm_build.extra_cxxflags / extra_ldflags plus what scripts/wasi-configure.sh
# passes to CMake. Wasm EH is a module-level feature, so the bridge, the
# archives and the runtimes must all agree — keep the three in sync.
#
# Env in:
#   WASI_SDK_PATH  path to wasi-sdk
#   MODEL          GGUF model to run against (a tiny one is fetched by default)
#   NODE           node binary (default: node)
#
# Node runs the wasm rather than a standalone CLI runtime: it accepts clang's
# default (legacy) wasm exception encoding, and it can supply the C++ exception
# TAG the module imports as env.__cpp_exception — a plain `wasmtime run` has no
# way to pass a tag import. wasm2go supplies the same tag, so this mirrors the
# real consumer.
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
: "${WASI_SDK_PATH:=$HOME/.config/wasmify/bin/wasi-sdk}"
: "${NODE:=node}"
OUT="$HERE/build-smoke"
EH_PREFIX="$HERE/deps/wasi-eh"
LIB="$HERE/build-wasi"

if [ ! -f "$LIB/src/libllama.a" ]; then
  echo "libllama.a not found — run: bash scripts/wasi-configure.sh && cmake --build build-wasi --target llama" >&2
  exit 1
fi

mkdir -p "$OUT"
: "${MODEL:=$OUT/stories260K.gguf}"
if [ ! -f "$MODEL" ]; then
  echo "== fetching a tiny test model"
  curl -fSL --proto '=https' --tlsv1.2 -o "$MODEL" \
    https://huggingface.co/ggml-org/models/resolve/main/tinyllamas/stories260K.gguf
fi

EMUL=(-D_WASI_EMULATED_SIGNAL -D_WASI_EMULATED_MMAN -D_WASI_EMULATED_PROCESS_CLOCKS -D_WASI_EMULATED_GETPID)
CXXFLAGS=(-O2 -std=gnu++17 -msimd128 -fwasm-exceptions "${EMUL[@]}"
          -nostdinc++ -isystem "$EH_PREFIX/include/c++/v1"
          -I"$HERE" -I"$HERE/llama.cpp/include" -I"$HERE/llama.cpp/ggml/include")
LDFLAGS=(-nostdlib++ -L"$EH_PREFIX/lib" -L"$LIB/src" -L"$LIB/ggml/src"
         -lllama -lggml -lggml-cpu -lggml-base
         -lc++ -lc++abi -lunwind -ldl
         -lwasi-emulated-process-clocks -lwasi-emulated-mman
         -lwasi-emulated-signal -lwasi-emulated-getpid
         -Wl,--allow-undefined-file="$HERE/scripts/allow-undefined.txt"
         -Wl,-z,stack-size=8388608)

echo "== building smoke.wasm"
"$WASI_SDK_PATH/bin/clang++" --target=wasm32-wasip1 "${CXXFLAGS[@]}" \
  "$HERE/llama_api.cc" "$HERE/tests/smoke.cc" -o "$OUT/smoke.wasm" "${LDFLAGS[@]}"

echo "== running under node"
exec "$NODE" "$HERE/scripts/run-smoke.js" "$OUT/smoke.wasm" "$MODEL"
