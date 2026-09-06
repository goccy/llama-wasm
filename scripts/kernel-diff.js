// kernel-diff.js — run dbg_* kernel exports of llama.wasm on a caller-supplied
// memory image, as a worker for the kernel differential gate
// (kernels/internal/asm, `make verify-kernels`).
//
// The gate runs every assembly override body and the C body it replaces (the
// dbg_* export compiled from the SAME llama.cpp commit) on identical inputs
// and compares the outputs, so a llama.cpp update that changes a kernel's
// layout or arithmetic fails the gate instead of silently running stale
// assembly. Node is the runtime for the same reasons as run-smoke.js: it
// accepts the legacy wasm exception encoding, lets the host supply the C++
// exception tag import, and runs memory64 modules.
//
// WASI is served by the small shim below rather than node's built-in WASI:
// that implementation takes 32-bit pointers, and this module is memory64
// (every WASI argument is an i64). The kernels themselves make no WASI
// calls; the shim exists for ggml's CPU initialisation (clock, getenv,
// logging) and reports an error code for everything else.
//
// Protocol, little-endian over stdin/stdout, one request per call:
//
//   request:  u32 nameLen, name
//             u32 nargs, per arg: u8 kind (0 i32, 1 i64, 2 f32, 3 f64),
//                                 u8 ptr, u16 pad, u32 pad, u64 bits
//             u32 nfix, per fixup: u64 offset (an 8-byte pointer field
//                                              inside the image to rebase)
//             u64 memLen, image
//   response: u8 status (0 ok, 1 error)
//             error: u32 msgLen, msg
//             ok:    u8 hasResult, u8 kind (1 i64, 3 f64), u16 pad, u32 pad,
//                    u64 bits, u64 memLen, image after the call
//
// The image is placed at a fixed base (the end of the module's initial
// memory, grown on demand); pointer arguments and fixup fields are rebased
// by that amount unless they are 0 (NULL stays NULL). The response image is
// the same region after the call, so the caller can compare every byte, not
// only the outputs it knows about. Anything the module writes to its stdout
// or stderr goes to this process's stderr: stdout is the protocol channel.
"use strict";
const fs = require("node:fs");
const crypto = require("node:crypto");

const ERRNO_SUCCESS = 0;
const ERRNO_BADF = 8;
const ERRNO_NOENT = 44;
const ERRNO_NOSYS = 52;

const wasmPath = process.argv[2];
if (!wasmPath) {
  console.error("usage: node kernel-diff.js <llama.wasm>");
  process.exit(2);
}

function readExact(n) {
  const b = Buffer.alloc(n);
  let off = 0;
  while (off < n) {
    let r;
    try {
      r = fs.readSync(0, b, off, n - off, null);
    } catch (e) {
      if (e.code === "EAGAIN") continue;
      if (e.code === "EOF") return null;
      throw e;
    }
    if (r === 0) return null;
    off += r;
  }
  return b;
}

function writeAll(fd, b) {
  let off = 0;
  while (off < b.length) {
    try {
      off += fs.writeSync(fd, b, off, b.length - off);
    } catch (e) {
      if (e.code === "EAGAIN") continue;
      throw e;
    }
  }
}

function respondError(msg) {
  const m = Buffer.from(String(msg), "utf8");
  const out = Buffer.alloc(1 + 4 + m.length);
  out[0] = 1;
  out.writeUInt32LE(m.length, 1);
  m.copy(out, 5);
  writeAll(1, out);
}

// wasiShim serves the module's WASI imports; state.memory is bound after
// instantiation and state.ptrBytes is the module's pointer width.
function wasiShim(state) {
  const view = () => new DataView(state.memory.buffer);
  const u8 = () => new Uint8Array(state.memory.buffer);
  const addr = (v) => Number(v);
  const putSize = (p, v) => {
    if (state.ptrBytes === 8) view().setBigUint64(addr(p), BigInt(v), true);
    else view().setUint32(addr(p), Number(v), true);
  };
  const getSize = (p) => (state.ptrBytes === 8 ? Number(view().getBigUint64(addr(p), true)) : view().getUint32(addr(p), true));
  return {
    environ_sizes_get: (countPtr, sizePtr) => { putSize(countPtr, 0); putSize(sizePtr, 0); return ERRNO_SUCCESS; },
    environ_get: () => ERRNO_SUCCESS,
    args_sizes_get: (countPtr, sizePtr) => { putSize(countPtr, 0); putSize(sizePtr, 0); return ERRNO_SUCCESS; },
    args_get: () => ERRNO_SUCCESS,
    clock_time_get: (id, precision, outPtr) => {
      const ns = Number(id) === 0 ? BigInt(Date.now()) * 1000000n : process.hrtime.bigint();
      view().setBigUint64(addr(outPtr), ns, true);
      return ERRNO_SUCCESS;
    },
    fd_write: (fd, iovs, iovsLen, nwrittenPtr) => {
      let total = 0;
      const chunks = [];
      for (let i = 0; i < Number(iovsLen); i++) {
        const p = addr(iovs) + 2 * state.ptrBytes * i;
        const ptr = getSize(p);
        const len = getSize(p + state.ptrBytes);
        chunks.push(Buffer.from(u8().subarray(ptr, ptr + len)));
        total += len;
      }
      if (Number(fd) === 1 || Number(fd) === 2) writeAll(2, Buffer.concat(chunks));
      putSize(nwrittenPtr, total);
      return ERRNO_SUCCESS;
    },
    random_get: (bufPtr, len) => { crypto.randomFillSync(u8(), addr(bufPtr), Number(len)); return ERRNO_SUCCESS; },
    sched_yield: () => ERRNO_SUCCESS,
    proc_exit: (code) => { throw new Error(`proc_exit(${code})`); },
    fd_close: () => ERRNO_BADF,
    fd_fdstat_get: () => ERRNO_BADF,
    fd_fdstat_set_flags: () => ERRNO_BADF,
    fd_prestat_get: () => ERRNO_BADF,
    fd_prestat_dir_name: () => ERRNO_BADF,
    fd_read: () => ERRNO_BADF,
    fd_readdir: () => ERRNO_BADF,
    fd_seek: () => ERRNO_BADF,
    path_filestat_get: () => ERRNO_NOENT,
    path_open: () => ERRNO_NOENT,
  };
}

async function instantiate() {
  const mod = await WebAssembly.compile(fs.readFileSync(wasmPath));
  const state = { memory: null, ptrBytes: 8 };
  const shim = wasiShim(state);
  const wasi = {};
  for (const imp of WebAssembly.Module.imports(mod)) {
    if (imp.module === "wasi_snapshot_preview1" && imp.kind === "function") {
      wasi[imp.name] = shim[imp.name] || (() => { console.error(`kernel-diff: unimplemented WASI import ${imp.name}`); return ERRNO_NOSYS; });
    }
  }
  const imports = {
    wasi_snapshot_preview1: wasi,
    // Host imports the kernels never reach: the wasmify callback trampoline
    // and the wasi-threads spawn.
    wasmify: { callback_invoke: () => { throw new Error("callback_invoke reached from a kernel"); } },
    wasi: { "thread-spawn": () => -1 },
  };
  // The C++ exception tag's payload is a pointer, so its width follows the
  // module's address width.
  let inst;
  try {
    imports.env = { __cpp_exception: new WebAssembly.Tag({ parameters: ["i64"] }) };
    inst = await WebAssembly.instantiate(mod, imports);
  } catch (e) {
    imports.env = { __cpp_exception: new WebAssembly.Tag({ parameters: ["i32"] }) };
    inst = await WebAssembly.instantiate(mod, imports);
    state.ptrBytes = 4;
  }
  state.memory = inst.exports.memory;
  if (typeof inst.exports._initialize === "function") inst.exports._initialize();
  if (typeof inst.exports.dbg_kernel_init !== "function") {
    throw new Error("llama.wasm has no dbg_kernel_init export: the bridge predates the kernel differential gate");
  }
  inst.exports.dbg_kernel_init();
  return { inst, memory64: state.ptrBytes === 8 };
}

(async () => {
  const { inst, memory64 } = await instantiate();
  const memory = inst.exports.memory;
  const base = memory.buffer.byteLength;
  const grow = (pages) => (memory64 ? memory.grow(BigInt(pages)) : memory.grow(pages));

  for (;;) {
    const h = readExact(4);
    if (h === null) break;
    const nameLen = h.readUInt32LE(0);
    const name = readExact(nameLen).toString("utf8");
    const nargs = readExact(4).readUInt32LE(0);
    const argSpec = readExact(16 * nargs);
    const nfix = readExact(4).readUInt32LE(0);
    const fixSpec = readExact(8 * nfix);
    const memLen = Number(readExact(8).readBigUInt64LE(0));
    const image = readExact(memLen);
    try {
      const fn = inst.exports[name];
      if (typeof fn !== "function") throw new Error(`no export ${name}`);
      const need = base + memLen - memory.buffer.byteLength;
      if (need > 0) grow(Math.ceil(need / 65536));
      const u8 = new Uint8Array(memory.buffer);
      u8.set(image, base);
      const view = new DataView(memory.buffer);
      for (let i = 0; i < nfix; i++) {
        const off = Number(fixSpec.readBigUInt64LE(8 * i));
        const v = view.getBigUint64(base + off, true);
        if (v !== 0n) view.setBigUint64(base + off, v + BigInt(base), true);
      }
      const args = [];
      for (let i = 0; i < nargs; i++) {
        const kind = argSpec[16 * i];
        const ptr = argSpec[16 * i + 1] !== 0;
        const bits = argSpec.readBigUInt64LE(16 * i + 8);
        switch (kind) {
          case 0: args.push(Number(BigInt.asIntN(32, bits))); break;
          case 1: {
            let v = BigInt.asIntN(64, bits);
            if (ptr && v !== 0n) v += BigInt(base);
            args.push(memory64 ? v : Number(v));
            break;
          }
          case 2: { const b = Buffer.alloc(4); b.writeUInt32LE(Number(bits & 0xffffffffn)); args.push(b.readFloatLE(0)); break; }
          case 3: { const b = Buffer.alloc(8); b.writeBigUInt64LE(bits); args.push(b.readDoubleLE(0)); break; }
          default: throw new Error(`bad arg kind ${kind}`);
        }
      }
      const ret = fn(...args);
      // Hand the pointer fields back in the caller's address space, so the
      // returned image differs from the caller's only where the kernel wrote.
      for (let i = 0; i < nfix; i++) {
        const off = Number(fixSpec.readBigUInt64LE(8 * i));
        const v = view.getBigUint64(base + off, true);
        if (v !== 0n) view.setBigUint64(base + off, v - BigInt(base), true);
      }
      const after = Buffer.from(new Uint8Array(memory.buffer, base, memLen));
      const out = Buffer.alloc(1 + 16 + 8 + memLen);
      out[0] = 0;
      if (ret !== undefined) {
        out[1] = 1;
        if (typeof ret === "bigint") { out[2] = 1; out.writeBigUInt64LE(BigInt.asUintN(64, ret), 9); }
        else { out[2] = 3; out.writeDoubleLE(ret, 9); }
      }
      out.writeBigUInt64LE(BigInt(memLen), 17);
      after.copy(out, 25);
      writeAll(1, out);
    } catch (e) {
      respondError(e && e.stack ? e.stack : e);
    }
  }
})().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});
