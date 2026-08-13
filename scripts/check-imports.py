#!/usr/bin/env python3
"""check-imports.py — assert the linked wasm imports nothing unexpected.

The wasm must import only WASI preview1, the C++ exception tag
`env.__cpp_exception`, and the callback entry point `wasmify.callback_invoke`
— both supplied by the generated Go bundle. Anything else is a host
dependency a Go consumer would have to implement, and is far cheaper to catch
here than as a link error in go-llama.

Usage: check-imports.py <module.wasm>
"""

import sys


def uleb(data, pos):
    result = shift = 0
    while True:
        byte = data[pos]
        pos += 1
        result |= (byte & 0x7F) << shift
        shift += 7
        if not byte & 0x80:
            return result, pos


def imports(data):
    """Yields (module, name, kind) for every import."""
    pos = 8  # magic + version
    while pos < len(data):
        section_id = data[pos]
        pos += 1
        size, pos = uleb(data, pos)
        if section_id != 2:
            pos += size
            continue
        p = pos
        count, p = uleb(data, p)
        for _ in range(count):
            mlen, p = uleb(data, p)
            module = data[p : p + mlen].decode()
            p += mlen
            nlen, p = uleb(data, p)
            name = data[p : p + nlen].decode()
            p += nlen
            kind = data[p]
            p += 1
            if kind == 0:  # func: typeidx
                _, p = uleb(data, p)
            elif kind == 1:  # table: reftype + limits
                p += 1
                flags = data[p]
                p += 1
                _, p = uleb(data, p)
                if flags & 1:
                    _, p = uleb(data, p)
            elif kind == 2:  # memory: limits
                flags = data[p]
                p += 1
                _, p = uleb(data, p)
                if flags & 1:
                    _, p = uleb(data, p)
            elif kind == 3:  # global: valtype + mutability
                p += 2
            elif kind == 4:  # tag: attribute + typeidx
                _, p = uleb(data, p)
                _, p = uleb(data, p)
            else:
                raise SystemExit(f"unknown import kind {kind}")
            yield module, name, kind
        return


def main():
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    data = open(sys.argv[1], "rb").read()

    allowed_env = {"__cpp_exception"}
    unexpected = []
    seen = 0
    for module, name, _kind in imports(data):
        seen += 1
        if module == "wasi_snapshot_preview1":
            continue
        if module == "wasi" and name == "thread-spawn":
            continue  # wasi-threads build; wasm2go runs each guest thread on a goroutine
        if module == "env" and name in allowed_env:
            continue
        if module == "wasmify" and name == "callback_invoke":
            # The bridge's callback entry point: C++ callback classes (the
            # token sink) call out through this single import, and the
            # generated Go registers the "wasmify" host module that
            # supplies it — no consumer wiring needed.
            continue
        unexpected.append(f"{module}.{name}")

    if unexpected:
        print("::error::unexpected wasm imports: " + ", ".join(sorted(unexpected)))
        raise SystemExit(1)
    print(f"wasm imports OK ({seen} total: WASI, the C++ exception tag, the callback entry)")


if __name__ == "__main__":
    main()
