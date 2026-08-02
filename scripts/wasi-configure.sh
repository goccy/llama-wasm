#!/bin/bash
# wasi-configure.sh — configure llama.cpp for wasm32-wasi using BY-NAME
# compilers so that wasmify's PATH-based compiler wrappers intercept every
# clang/clang++ invocation the build issues.
#
# Two things happen here that wasmify cannot do for us:
#
#  1. CMake configuration. wasmify owns compilation and flag transforms; it
#     does not own configuration, so the cache has to be primed with a
#     target-correct compiler, sysroot and option set. The compilers are named
#     bare (`clang` / `clang++`) with $WASI_SDK_PATH/bin prepended to PATH:
#     under `wasmify build`, CC/CXX are overridden to the wrapper dir, and the
#     wrapper resolves WASMIFY_REAL_clang (= $WASI_SDK_PATH/bin/clang, found on
#     PATH) and execs it.
#
#  2. The C++ runtimes. llama.cpp throws (GGUF loading, std::runtime_error),
#     so the wasm needs real exception support, and wasi-sdk ships libc++abi
#     built WITHOUT it — linking against the stock runtimes fails with
#     undefined __cxa_throw / __cpp_exception / _Unwind_CallPersonality. We
#     build libunwind + libc++abi + libc++ once from the matching LLVM release
#     with -fwasm-exceptions and install them under deps/wasi-eh, which the
#     compile and link flags below point at. The result is cached by a .tag
#     stamp, so a re-run is free.
#
# Env in:
#   WASI_SDK_PATH   path to wasi-sdk (defaults to wasmify's shared XDG path)
#   LLAMA_THREADS   1 to configure the wasm32-wasip1-threads build
# Runs from the project root (the directory containing llama.cpp/).
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$HERE/llama.cpp"
: "${WASI_SDK_PATH:=$HOME/.config/wasmify/bin/wasi-sdk}"
: "${LLAMA_THREADS:=0}"

if [ ! -d "$SRC/ggml" ]; then
  echo "llama.cpp submodule is empty — run: git submodule update --init --recursive" >&2
  exit 1
fi

export PATH="$WASI_SDK_PATH/bin:$PATH"

TRIPLE="wasm32-wasip1"
TOOLCHAIN="$WASI_SDK_PATH/share/cmake/wasi-sdk-p1.cmake"
if [ "$LLAMA_THREADS" = "1" ]; then
  TRIPLE="wasm32-wasip1-threads"
  TOOLCHAIN="$WASI_SDK_PATH/share/cmake/wasi-sdk-pthread.cmake"
fi

EH_PREFIX="$HERE/deps/wasi-eh"
BUILD_DIR="$HERE/build-wasi"

echo "== wasi sdk:  $WASI_SDK_PATH"
echo "== triple:    $TRIPLE"

# ---------------------------------------------------------------------------
# C++ runtimes with wasm exception handling.
# ---------------------------------------------------------------------------
bash "$HERE/scripts/build-eh-runtimes.sh"

# ---------------------------------------------------------------------------
# CMake configure.
#
# The flags below are the ones the whole link must agree on — they are mirrored
# in wasmify.json's wasm_build.extra_cxxflags (which govern the BRIDGE compile)
# and in scripts/run-smoke.sh. Wasm EH is a module-level feature: an archive
# built without it cannot be linked against a bridge built with it.
#
#   -fwasm-exceptions   llama.cpp throws; wasi-sdk's default is no EH at all
#   -msimd128           ggml has hand-written wasm SIMD kernels
#   -D_WASI_EMULATED_*  ggml/llama reference signal, mman, clock and getpid
#                       APIs wasi-libc only provides as emulation libraries
# ---------------------------------------------------------------------------
EMUL="-D_WASI_EMULATED_SIGNAL -D_WASI_EMULATED_MMAN -D_WASI_EMULATED_PROCESS_CLOCKS -D_WASI_EMULATED_GETPID"
CFLAGS="-msimd128 $EMUL"
CXXFLAGS="-msimd128 -fwasm-exceptions $EMUL -nostdinc++ -isystem $EH_PREFIX/include/c++/v1"

rm -rf "$BUILD_DIR"
cmake -S "$SRC" -B "$BUILD_DIR" \
  -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN" \
  -DCMAKE_C_COMPILER=clang \
  -DCMAKE_CXX_COMPILER=clang++ \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=OFF \
  -DLLAMA_BUILD_TESTS=OFF \
  -DLLAMA_BUILD_EXAMPLES=OFF \
  -DLLAMA_BUILD_SERVER=OFF \
  -DLLAMA_BUILD_TOOLS=OFF \
  -DLLAMA_CURL=OFF \
  -DGGML_NATIVE=OFF \
  -DGGML_BACKEND_DL=OFF \
  -DGGML_OPENMP=OFF \
  -DCMAKE_C_FLAGS="$CFLAGS" \
  -DCMAKE_CXX_FLAGS="$CXXFLAGS"

echo "== configured: $BUILD_DIR"
