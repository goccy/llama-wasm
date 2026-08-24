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

# The threads flavor follows wasmify.json's bridge.HostThreads unless the
# caller overrides it: the priming build must use the same thread model as
# the wasmify replay, or the replay's --shared-memory link flags meet
# non-atomics sysroot objects and the configure try-compile fails.
: "${LLAMA_THREADS:=$(grep -q "\"HostThreads\": true" "$HERE/wasmify.json" && echo 1 || echo 0)}"
: "${WASI_SDK_PATH:=$HOME/.config/wasmify/bin/wasi-sdk}"

if [ ! -d "$HERE/llama.cpp/ggml" ]; then
  echo "llama.cpp submodule is empty — run: git submodule update --init --recursive" >&2
  exit 1
fi

# Apply the project's llama.cpp patches: sources the upstream tree does
# not carry (the wasm q8_0 repack kernels). Idempotent — a fresh
# checkout applies each patch, a tree that already has it is left
# alone, and anything in between is an error rather than a silent
# half-patched build.
for p in "$HERE"/patches/*.patch; do
  [ -e "$p" ] || continue
  if git -C "$HERE/llama.cpp" apply --check "$p" 2>/dev/null; then
    git -C "$HERE/llama.cpp" apply "$p"
    echo "== applied patch: $(basename "$p")"
  elif git -C "$HERE/llama.cpp" apply --reverse --check "$p" 2>/dev/null; then
    echo "== patch already applied: $(basename "$p")"
  else
    echo "patch does not apply cleanly: $p" >&2
    exit 1
  fi
done

echo "== wasi sdk:  $WASI_SDK_PATH"
bash "$HERE/scripts/build-eh-runtimes.sh"
