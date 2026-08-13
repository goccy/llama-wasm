#!/bin/bash
# wasi-build.sh — configure AND build llama.cpp for wasm32-wasip1.
#
# Both halves live here, and both run inside `wasmify build`, because CMake
# resolves the compiler exactly once and bakes the ABSOLUTE path into
# CMakeCache.txt. wasmify records the build by putting wrapper executables on
# PATH and in CC/CXX; configuring outside that phase would bake wasi-sdk's own
# clang, every compilation would bypass the wrapper, and the build log would
# come out empty — leaving `wasmify generate-build` nothing to turn into
# build.json and `wasm-build` nothing to replay.
#
# A script rather than an inline command in wasmify.json for two more reasons:
#
#  1. wasmify runs the build with the working directory set to the project's
#     root_dir (llama.cpp/), not the repository root, so relative paths in the
#     JSON would resolve against the wrong place. This computes the repository
#     root from its own location instead. (wasmify.json therefore invokes it as
#     `bash ../scripts/wasi-build.sh`.)
#  2. wasmify appends the selected target's `build_target` to the command line.
#     `cmake --build` rejects a positional argument; a script just ignores it.
#
# Env in (all set by `wasmify build`):
#   CC, CXX        the wrapper executables — used as the CMake compilers
#   WASI_SDK_PATH  path to wasi-sdk
#   LLAMA_THREADS  1 to build for wasm32-wasip1-threads
#   JOBS           parallelism (defaults to the machine's CPU count)
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$HERE/llama.cpp"
BUILD_DIR="$HERE/build-wasi"
EH_PREFIX="$HERE/deps/wasi-eh"
: "${WASI_SDK_PATH:=$HOME/.config/wasmify/bin/wasi-sdk}"
: "${LLAMA_THREADS:=0}"

if [ ! -d "$EH_PREFIX/include/c++/v1" ]; then
  echo "$EH_PREFIX is missing — run scripts/wasi-configure.sh first" >&2
  exit 1
fi

# Pick the compilers.
#
# Under `wasmify build`, CC/CXX name the wrapper's `cc` / `c++` shims. Those
# are the WRONG ones here: each shim execs the tool of the same name resolved
# on PATH, and wasi-sdk ships no `cc`, so `cc` falls through to the host gcc
# and the whole thing cross-compiles for the build machine. The wrapper also
# provides `clang` / `clang++` shims, which bind to wasi-sdk's clang — use
# those. Outside `wasmify build` (a manual run, or the smoke test's
# prerequisites) CC/CXX are unset and wasi-sdk's compilers are used directly.
export PATH="$WASI_SDK_PATH/bin:$PATH"
if [ -n "${CC:-}" ]; then
  WRAPPER_DIR="$(dirname "$CC")"
  CMAKE_CC="$WRAPPER_DIR/clang"
  CMAKE_CXX="$WRAPPER_DIR/clang++"
  # The archive step has to be recorded too: wasmify replays the compiles into
  # object files and then links the ARCHIVES the build produced, so an `ar`
  # invocation it never saw leaves it with nothing to link. wasi-sdk provides
  # `ar` / `ranlib` under those bare names, so the wrapper's shims resolve to
  # the right tools.
  CMAKE_AR="$WRAPPER_DIR/ar"
  CMAKE_RANLIB="$WRAPPER_DIR/ranlib"
else
  CMAKE_CC="$WASI_SDK_PATH/bin/clang"
  CMAKE_CXX="$WASI_SDK_PATH/bin/clang++"
  CMAKE_AR="$WASI_SDK_PATH/bin/ar"
  CMAKE_RANLIB="$WASI_SDK_PATH/bin/ranlib"
fi

TRIPLE="wasm32-wasip1"
SDK_TOOLCHAIN="$WASI_SDK_PATH/share/cmake/wasi-sdk-p1.cmake"
if [ "$LLAMA_THREADS" = "1" ]; then
  TRIPLE="wasm32-wasip1-threads"
  SDK_TOOLCHAIN="$WASI_SDK_PATH/share/cmake/wasi-sdk-pthread.cmake"
fi
# wasi-sdk's toolchain file `set()`s the compilers unconditionally, which beats
# -DCMAKE_C_COMPILER= on the command line and would route every compile past
# wasmify's wrapper. Wrap it in a shim that includes it and then restores our
# choice.
#
# The shim is GENERATED with the paths baked in rather than reading them from
# cache variables: CMake re-includes the toolchain file inside every
# try_compile sub-project, and -D definitions do not propagate there (they
# would need CMAKE_TRY_COMPILE_PLATFORM_VARIABLES). Baking them in keeps the
# compiler-ABI probes working. It lands in the build directory because the
# wrapper path changes every run.
TOOLCHAIN="$BUILD_DIR/wasi-toolchain.cmake"

if [ -z "${JOBS:-}" ]; then
  JOBS="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)"
fi

echo "== triple:   $TRIPLE"
echo "== compiler: $CMAKE_CXX"

# The flags below are the ones the whole link must agree on — they are mirrored
# in wasmify.json's wasm_build.extra_cxxflags (which govern the BRIDGE compile)
# and in scripts/run-smoke.sh. Wasm EH is a module-level feature: an archive
# built without it cannot be linked against a bridge built with it.
#
#   -fwasm-exceptions   llama.cpp throws; wasi-sdk's default is no EH at all
#   -msimd128           ggml has hand-written wasm SIMD kernels
#   -D_WASI_EMULATED_*  ggml/llama reference signal, mman, clock and getpid
#                       APIs wasi-libc only provides as emulation libraries
#
# The EH runtimes replace only the LIBRARIES, not the headers: they are built
# from the same LLVM release wasi-sdk ships, so libc++'s headers are identical
# and wasi-sdk's own include path is correct. Passing -nostdinc++ with an
# -isystem override would also break `wasmify parse-headers`, which re-runs
# clang over the header with these flags and cannot resolve libc++'s
# #include_next of the C <math.h> that way.
EMUL="-D_WASI_EMULATED_SIGNAL -D_WASI_EMULATED_MMAN -D_WASI_EMULATED_PROCESS_CLOCKS -D_WASI_EMULATED_GETPID"
CFLAGS="-msimd128 $EMUL"
CXXFLAGS="-msimd128 -fwasm-exceptions $EMUL"

# Configure from scratch every time: the compiler path baked into the cache is
# the wrapper's, and the wrapper lives in a per-run temporary directory.
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cat > "$TOOLCHAIN" <<TOOLCHAIN_EOF
# Generated by scripts/wasi-build.sh — wasi-sdk's toolchain file with the
# compiler left as whoever invoked the build chose (wasmify's recording
# wrapper, normally). The wrapper execs wasi-sdk's clang underneath, so the
# compilation is identical; it is merely observed.
include("$SDK_TOOLCHAIN")
set(CMAKE_C_COMPILER "$CMAKE_CC")
set(CMAKE_ASM_COMPILER "$CMAKE_CC")
set(CMAKE_CXX_COMPILER "$CMAKE_CXX")
set(CMAKE_AR "$CMAKE_AR")
set(CMAKE_RANLIB "$CMAKE_RANLIB")
TOOLCHAIN_EOF

# Configure with the recording log pointed at a throwaway file. CMake probes
# the compiler by building a handful of its own sources (CMakeCCompilerId.c,
# the ABI checks, each try_compile a feature test runs) in scratch directories
# it deletes afterwards. Those are not part of the project, and replaying them
# later fails on the vanished directories — so they must not reach the build
# log that becomes build.json. The wrapper reads WASMIFY_LOG_FILE per
# invocation, so overriding it for this one command is enough; the build below
# inherits the real one.
WASMIFY_LOG_FILE="$BUILD_DIR/cmake-probes.log" \
cmake -S "$SRC" -B "$BUILD_DIR" \
  -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN" \
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

# `llama` pulls in the ggml backends it links against, so this one target
# produces every archive wasm-build needs.
exec cmake --build "$BUILD_DIR" --target llama --parallel "$JOBS"
