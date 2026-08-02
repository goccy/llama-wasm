#!/bin/bash
# wasi-configure.sh — prepare everything the wasm build of llama.cpp needs
# BEFORE wasmify's compiler wrappers come into play.
#
# That is exactly one thing: the C++ runtimes. llama.cpp throws (GGUF loading
# raises std::runtime_error and the code catches internally), so the wasm needs
# real exception support, and wasi-sdk ships libc++abi built WITHOUT it —
# linking against the stock runtimes fails with undefined __cxa_throw /
# __cpp_exception / _Unwind_CallPersonality. scripts/build-eh-runtimes.sh
# rebuilds libunwind + libc++abi + libc++ from the matching LLVM release with
# -fwasm-exceptions and installs them under deps/wasi-eh. A .tag stamp makes a
# re-run free.
#
# The CMake configure of llama.cpp itself deliberately does NOT happen here: it
# belongs to the build phase. CMake resolves the compiler once and bakes the
# ABSOLUTE path into CMakeCache.txt, so configuring outside `wasmify build`
# would bake wasi-sdk's clang and every compilation would bypass wasmify's
# wrapper — the build log would come out empty and there would be nothing to
# replay. See scripts/wasi-build.sh.
#
# Env in:
#   WASI_SDK_PATH   path to wasi-sdk (defaults to wasmify's shared XDG path)
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
: "${WASI_SDK_PATH:=$HOME/.config/wasmify/bin/wasi-sdk}"

if [ ! -d "$HERE/llama.cpp/ggml" ]; then
  echo "llama.cpp submodule is empty — run: git submodule update --init --recursive" >&2
  exit 1
fi

echo "== wasi sdk:  $WASI_SDK_PATH"
bash "$HERE/scripts/build-eh-runtimes.sh"
