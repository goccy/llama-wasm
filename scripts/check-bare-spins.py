#!/usr/bin/env python3
"""check-bare-spins.py — assert the wasm contains no bare atomic spin loops.

A "bare atomic spin loop" is a `loop` whose body reaches its back-branch
having performed an atomic load but no call of any kind. On the wasm2go
host every guest thread is a goroutine, and a call-free loop is lowered
to assembly the Go runtime cannot async-preempt: if a stop-the-world
begins while one worker spins on such a loop and the worker it waits for
is already parked, neither the GC nor the barrier can ever complete and
the process livelocks. ggml's spin-waits must therefore contain a call
(sched_yield via ggml_thread_cpu_relax — see
patches/wasm-spin-sched-yield.patch).

This gate exists because patch application alone is not proof: a stale
object cache once shipped a release built from unpatched sources while
the build log still printed "applied patch". Checking the artifact is
the only evidence that counts.

The scan parses `wasm-objdump -d` output (wabt). That output is another
tool's text format, so the parse is total: every line either matches the
expected `addr: bytes | mnemonic` shape, is a function header, or is
ignored as non-code output; any loop we cannot follow is reported as a
finding rather than silently skipped.

The check is loop-granular, not path-sensitive: one call anywhere in a
loop body clears the whole loop, so a call-free spin subpath inside a
loop that also does calling work would pass. That approximation is fine
for the shape ggml emits — its barrier/poll spins are minimal loops —
and keeps the gate free of false reds.

Usage: check-bare-spins.py <module.wasm>
Exit 0 when no bare atomic spin loop exists, 1 otherwise (or on any
failure to produce/parse the disassembly).
"""

import re
import shutil
import subprocess
import sys

# Instruction line: "  20ac9: 03 40  |     loop" (address, raw bytes, mnemonic).
INSN = re.compile(r"^\s*([0-9a-f]+):(?:\s[0-9a-f]{2})+\s*\|\s*(\S+)(.*)$")
# Function header: " 28a587 func[3052]:" (optionally "... <name>:").
FUNC = re.compile(r"^\s*[0-9a-f]+\s+func\[(\d+)\]")

# Constructs that push a label onto the control stack. `try` is the
# legacy-EH block form; `else`/`catch`/`catch_all` continue an existing
# construct and neither push nor pop.
PUSHES = {"block", "loop", "if", "try"}
# `end` closes block/loop/if/try; `delegate` closes a try.
POPS = {"end", "delegate"}
# Anything that reaches the host or another function is a preemption
# point: plain and tail calls, throws, and the blocking atomic waits
# (which park the goroutine instead of spinning).
CALLS = {
    "call",
    "call_indirect",
    "return_call",
    "return_call_indirect",
    "throw",
    "rethrow",
    "memory.atomic.wait32",
    "memory.atomic.wait64",
}
BRANCHES = {"br", "br_if", "br_table"}


class Loop:
    __slots__ = ("addr", "atomic", "call", "reported")

    def __init__(self, addr):
        self.addr = addr
        self.atomic = False
        self.call = False
        self.reported = False


def scan(disasm):
    """Yields (func_index, loop_addr, branch_addr) for every bare spin."""
    func = None
    # Control stack entries: Loop for `loop`, None for other constructs.
    stack = []
    for line in disasm.splitlines():
        header = FUNC.match(line)
        if header:
            func = int(header.group(1))
            stack = []
            continue
        m = INSN.match(line)
        if not m:
            continue
        addr, mnemonic, rest = m.group(1), m.group(2), m.group(3)
        if mnemonic in PUSHES:
            stack.append(Loop(addr) if mnemonic == "loop" else None)
        elif mnemonic in POPS:
            if stack:
                stack.pop()
        elif mnemonic in CALLS:
            for entry in stack:
                if entry is not None:
                    entry.call = True
        elif ".atomic.load" in mnemonic:
            for entry in stack:
                if entry is not None:
                    entry.atomic = True
        elif mnemonic in BRANCHES:
            # A branch names label depths relative to the innermost
            # construct; br_table carries several. A depth past the
            # stack targets the function body (never a loop).
            for depth in (int(d) for d in re.findall(r"\d+", rest)):
                idx = len(stack) - 1 - depth
                if 0 <= idx < len(stack):
                    entry = stack[idx]
                    if (
                        entry is not None
                        and entry.atomic
                        and not entry.call
                        and not entry.reported
                    ):
                        entry.reported = True
                        yield func, entry.addr, addr


def main():
    if len(sys.argv) != 2:
        print(__doc__, file=sys.stderr)
        return 1
    if shutil.which("wasm-objdump") is None:
        print("check-bare-spins: wasm-objdump (wabt) not found", file=sys.stderr)
        return 1
    proc = subprocess.run(
        ["wasm-objdump", "-d", sys.argv[1]],
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0:
        sys.stderr.write(proc.stderr)
        print("check-bare-spins: wasm-objdump failed", file=sys.stderr)
        return 1

    findings = list(scan(proc.stdout))
    if findings:
        for func, loop_addr, branch_addr in findings:
            print(
                f"bare atomic spin loop: func[{func}] "
                f"loop@0x{loop_addr} back-branch@0x{branch_addr}"
            )
        print(
            f"check-bare-spins: {len(findings)} call-free atomic spin "
            "loop(s) — non-preemptible on the wasm2go host; "
            "was patches/wasm-spin-sched-yield.patch compiled in?",
            file=sys.stderr,
        )
        return 1
    print("check-bare-spins: OK — every atomic spin loop contains a call")
    return 0


if __name__ == "__main__":
    sys.exit(main())
