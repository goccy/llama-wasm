// run-smoke.js — run the bridge smoke wasm under Node's WASI.
//
// Node is the runtime here rather than wasmtime for two reasons: it accepts
// clang's default (legacy) wasm exception encoding, and it lets the host supply
// the C++ exception TAG the module imports as env.__cpp_exception. Standalone
// CLI runtimes provide no way to pass a tag import. wasm2go supplies the same
// tag when it runs the module, so this mirrors the real consumer.
const { readFileSync } = require("node:fs");
const { dirname } = require("node:path");
const { WASI } = require("node:wasi");

const [wasmPath, modelPath] = process.argv.slice(2);
if (!wasmPath || !modelPath) {
  console.error("usage: node run-smoke.js <smoke.wasm> <model.gguf>");
  process.exit(2);
}

const dir = dirname(modelPath);
const wasi = new WASI({
  version: "preview1",
  args: ["smoke", modelPath],
  preopens: { [dir]: dir },
});

(async () => {
  const wasm = await WebAssembly.compile(readFileSync(wasmPath));
  const imports = wasi.getImportObject();
  imports.env = { __cpp_exception: new WebAssembly.Tag({ parameters: ["i32"] }) };
  process.exitCode = wasi.start(await WebAssembly.instantiate(wasm, imports));
})().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});
