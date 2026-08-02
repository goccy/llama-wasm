#!/bin/bash
# build-eh-runtimes.sh — build libunwind + libc++abi + libc++ for
# wasm32-wasip1 WITH wasm exception handling, into deps/wasi-eh.
#
# Why this exists: llama.cpp throws — model loading raises std::runtime_error,
# and the code catches internally, so -fno-exceptions is not an option. wasi-sdk
# ships its C++ runtimes built WITHOUT exception support, so linking a
# -fwasm-exceptions object against them fails with undefined __cxa_throw,
# __cxa_begin_catch, __cpp_exception and _Unwind_CallPersonality. The fix is to
# rebuild the three runtime libraries from the LLVM release matching wasi-sdk's
# clang, with -fwasm-exceptions.
#
# Idempotent: a .tag stamp recording the LLVM version short-circuits a re-run.
#
# Env in:
#   WASI_SDK_PATH  path to wasi-sdk
#   LLVM_VERSION   LLVM release to build the runtimes from (default: read from
#                  wasi-sdk's VERSION file, which records llvm-version)
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
: "${WASI_SDK_PATH:=$HOME/.config/wasmify/bin/wasi-sdk}"
PREFIX="$HERE/deps/wasi-eh"
WORK="$HERE/deps/llvm-src"

if [ -z "${LLVM_VERSION:-}" ]; then
  # wasi-sdk's VERSION file carries `llvm-version: 22.1.0`.
  LLVM_VERSION="$(sed -n 's/^llvm-version:[[:space:]]*//p' "$WASI_SDK_PATH/VERSION" | head -1)"
fi
if [ -z "$LLVM_VERSION" ]; then
  echo "cannot determine the LLVM version wasi-sdk was built from" >&2
  exit 1
fi

if [ -f "$PREFIX/.tag" ] && [ "$(cat "$PREFIX/.tag")" = "$LLVM_VERSION" ]; then
  echo "== EH runtimes already built for LLVM $LLVM_VERSION"
  exit 0
fi

echo "== building EH-enabled C++ runtimes from LLVM $LLVM_VERSION"
mkdir -p "$HERE/deps"
SRC="$WORK/llvm-project-$LLVM_VERSION.src"

if [ ! -d "$SRC/runtimes" ]; then
  mkdir -p "$WORK"
  TARBALL="$WORK/llvm-project-$LLVM_VERSION.src.tar.xz"
  if [ ! -f "$TARBALL" ]; then
    curl -fSL --proto '=https' --tlsv1.2 -o "$TARBALL" \
      "https://github.com/llvm/llvm-project/releases/download/llvmorg-$LLVM_VERSION/llvm-project-$LLVM_VERSION.src.tar.xz"
  fi
  # Only the runtimes and the cmake modules they include. libc/ comes along
  # because libcxx's from_chars includes libc/shared/fp_bits.h.
  tar -xf "$TARBALL" -C "$WORK" \
    "llvm-project-$LLVM_VERSION.src/runtimes" \
    "llvm-project-$LLVM_VERSION.src/libcxx" \
    "llvm-project-$LLVM_VERSION.src/libcxxabi" \
    "llvm-project-$LLVM_VERSION.src/libunwind" \
    "llvm-project-$LLVM_VERSION.src/libc" \
    "llvm-project-$LLVM_VERSION.src/cmake" \
    "llvm-project-$LLVM_VERSION.src/llvm/cmake"
fi

# wasi-libc has no copy_file_range; libcxx enables it for every musl-like libc.
OPS="$SRC/libcxx/src/filesystem/operations.cpp"
if grep -q '^#if _LIBCPP_GLIBC_PREREQ(2, 27) || _LIBCPP_HAS_MUSL_LIBC || defined(__FreeBSD__)$' "$OPS"; then
  sed -i.bak 's|^#if _LIBCPP_GLIBC_PREREQ(2, 27) || _LIBCPP_HAS_MUSL_LIBC || defined(__FreeBSD__)$|#if (_LIBCPP_GLIBC_PREREQ(2, 27) \|\| _LIBCPP_HAS_MUSL_LIBC \|\| defined(__FreeBSD__)) \&\& !defined(__wasi__)|' "$OPS"
fi

BUILD="$WORK/build-eh"
rm -rf "$BUILD"
# Notes on the non-obvious options:
#   UNIX=ON            HandleLLVMOptions bails with "Unable to determine
#                      platform" for the wasi triple otherwise.
#   -fdeclspec         libunwind's config.h picks the __declspec branch on a
#                      non-ELF target.
#   THREADS/PTHREAD_API ON   matches how wasi-sdk builds its own libc++ (against
#                      wasip1's stub pthread); llama.cpp references std::thread
#                      symbols, which are otherwise undefined.
cmake -S "$SRC/runtimes" -B "$BUILD" -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE="$WASI_SDK_PATH/share/cmake/wasi-sdk-p1.cmake" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DUNIX:BOOL=ON \
  -DLLVM_ENABLE_RUNTIMES="libunwind;libcxxabi;libcxx" \
  -DCMAKE_C_FLAGS="-fwasm-exceptions -fdeclspec" \
  -DCMAKE_CXX_FLAGS="-fwasm-exceptions -fdeclspec" \
  -DLIBCXX_ENABLE_EXCEPTIONS=ON -DLIBCXXABI_ENABLE_EXCEPTIONS=ON \
  -DLIBCXX_ENABLE_THREADS=ON -DLIBCXXABI_ENABLE_THREADS=ON -DLIBUNWIND_ENABLE_THREADS=ON \
  -DLIBCXX_HAS_PTHREAD_API=ON -DLIBCXXABI_HAS_PTHREAD_API=ON \
  -DLIBCXX_ENABLE_SHARED=OFF -DLIBCXXABI_ENABLE_SHARED=OFF -DLIBUNWIND_ENABLE_SHARED=OFF \
  -DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON -DLIBCXX_CXX_ABI=libcxxabi \
  -DLIBCXX_ABI_VERSION=2 -DLIBCXX_HAS_MUSL_LIBC=ON \
  -DLIBCXXABI_USE_LLVM_UNWINDER=OFF \
  -DLIBCXX_INCLUDE_BENCHMARKS=OFF -DLIBCXX_INCLUDE_TESTS=OFF \
  -DCMAKE_C_COMPILER_WORKS=ON -DCMAKE_CXX_COMPILER_WORKS=ON >/dev/null

ninja -C "$BUILD" >/dev/null
ninja -C "$BUILD" install >/dev/null
echo "$LLVM_VERSION" > "$PREFIX/.tag"
echo "== EH runtimes installed: $PREFIX"
