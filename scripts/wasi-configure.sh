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
# not carry (the wasm kernels and their exports). The series is stacked —
# later patches modify files earlier ones create — so it is applied as a
# whole from the pinned commit. A fresh checkout takes the series directly.
# A tree that already carries it (a local rebuild) is put back to the pinned
# commit first, but only on the paths the series touches, which
# `git apply --numstat` reports without applying anything; a change outside
# those paths is someone's work in progress and is left alone with an error
# rather than reset or half-patched.
# In CI the build runs as root in a container over a checkout owned by the
# runner user, which git refuses to read ("dubious ownership") unless the
# directory is marked safe; the mark is passed per command rather than
# written into anyone's global config.
lgit() { git -c "safe.directory=$HERE/llama.cpp" -C "$HERE/llama.cpp" "$@"; }
series=("$HERE"/patches/*.patch)
if [ -e "${series[0]}" ]; then
  touched=$(lgit apply --numstat "${series[@]}" | cut -f3 | sort -u)
  dirty=$(lgit status --porcelain --untracked-files=all | cut -c4- | sort -u)
  if [ -n "$dirty" ]; then
    foreign=$(comm -23 <(printf '%s\n' "$dirty") <(printf '%s\n' "$touched"))
    if [ -n "$foreign" ]; then
      echo "llama.cpp has local changes outside the patch series; commit them into a patch or reset them:" >&2
      printf '  %s\n' $foreign >&2
      exit 1
    fi
    while IFS= read -r path; do
      [ -n "$path" ] || continue
      if lgit ls-files --error-unmatch -- "$path" >/dev/null 2>&1; then
        lgit checkout -q -- "$path"
      else
        rm -f "$HERE/llama.cpp/$path"
      fi
    done <<< "$dirty"
    echo "== reset $(printf '%s\n' "$dirty" | wc -l | tr -d ' ') patched path(s) to the pinned llama.cpp"
  fi
  for p in "${series[@]}"; do
    lgit apply "$p"
    echo "== applied patch: $(basename "$p")"
  done
fi

echo "== wasi sdk:  $WASI_SDK_PATH"
bash "$HERE/scripts/build-eh-runtimes.sh"
