package asm

// Kernel differential gate.
//
// Every assembly override replaces one C function of the pinned llama.cpp
// commit — the dbg_* export the patches in patches/ put on that body. The
// unit gates in this package check each body against a float reference we
// wrote, which says the assembly computes what WE think the format means. It
// does not say the assembly still computes what llama.cpp computes: a
// llama.cpp update can change a repacked block layout, an activation
// quantizer or a fold order without touching the export's signature, and the
// override would keep running the old arithmetic on new data.
//
// So, when llama.wasm is available, every run tree also replays each kernel
// call on the C body: the same memory image and arguments go to the dbg_*
// export of llama.wasm (run under node by scripts/kernel-diff.js), and the
// two output images are compared byte for byte outside the declared outputs
// and to a tolerance inside them. `make verify-kernels` builds llama.wasm
// incrementally and runs the gates with -require-llama-wasm, so a kernel
// change cannot be pushed without its C body agreeing; CI runs the same
// command with the llama.wasm the build job produced.

import (
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"sort"
	"strings"
	"sync"
	"testing"
)

var (
	llamaWasmFlag = flag.String("llama-wasm", "",
		"llama.wasm to replay each kernel call on (default: <repo>/.wasmify/wasm-build/output/llama.wasm)")
	requireLlamaWasm = flag.Bool("require-llama-wasm", false,
		"fail when llama.wasm or node is missing instead of skipping the wasm differential, and fail when any export with a body for this host was not compared")
)

// refState is what the run trees need to replay kernel calls on the wasm.
type refState struct {
	enabled bool
	reason  string // why it is disabled
	script  string // scripts/kernel-diff.js
	wasm    string // llama.wasm
}

var (
	refOnce  sync.Once
	refCache refState
)

// repoRoot is the llama-wasm checkout this package lives in.
func repoRoot() string {
	_, self, _, _ := runtime.Caller(0) // kernels/internal/asm/wasmref_test.go
	return filepath.Clean(filepath.Join(filepath.Dir(self), "..", "..", ".."))
}

func ref() refState {
	refOnce.Do(func() {
		root := repoRoot()
		st := refState{
			script: filepath.Join(root, "scripts", "kernel-diff.js"),
			wasm:   *llamaWasmFlag,
		}
		if st.wasm == "" {
			st.wasm = filepath.Join(root, ".wasmify", "wasm-build", "output", "llama.wasm")
		}
		if _, err := os.Stat(st.wasm); err != nil {
			st.reason = fmt.Sprintf("llama.wasm not found at %s (build it with `make wasm-build`)", st.wasm)
			refCache = st
			return
		}
		if _, err := exec.LookPath("node"); err != nil {
			st.reason = "node is not on PATH"
			refCache = st
			return
		}
		st.enabled = true
		refCache = st
	})
	return refCache
}

// refCompared collects the exports whose C body was compared by a run tree
// that executed on this host; TestMain checks it against the manifest in
// -require-llama-wasm mode.
var (
	refComparedMu sync.Mutex
	refCompared   = map[string]bool{}
)

// refComparedFile is where a run tree records the exports it compared: one
// export name per line, appended after each successful comparison.
const refComparedFile = "ref-compared.txt"

// collectCompared reads a finished run tree's record into refCompared.
func collectCompared(dir string) {
	data, err := os.ReadFile(filepath.Join(dir, refComparedFile))
	if err != nil {
		return
	}
	refComparedMu.Lock()
	defer refComparedMu.Unlock()
	for _, line := range strings.Split(string(data), "\n") {
		if line = strings.TrimSpace(line); line != "" {
			refCompared[line] = true
		}
	}
}

// refSource renders the run tree's ref.go: the wasm replay client plus this
// tree's kernel-symbol -> export bindings. pkg is the run tree's package
// name; bindings are (symbol, export) pairs.
func refSource(t *testing.T, pkg, dir string, bindings []string) string {
	t.Helper()
	if len(bindings)%2 != 0 {
		t.Fatalf("writeRunTree: bindings must be (symbol, export) pairs, got %d strings", len(bindings))
	}
	st := ref()
	var b strings.Builder
	fmt.Fprintf(&b, "package %s\n\n", pkg)
	b.WriteString(refClientImports)
	fmt.Fprintf(&b, "const (\n\trefEnabled = %v\n\trefScript  = %q\n\trefWasm    = %q\n\trefRecord  = %q\n)\n\n",
		st.enabled, st.script, st.wasm, filepath.Join(dir, refComparedFile))
	b.WriteString("var refExports = map[string]string{\n")
	for i := 0; i+1 < len(bindings); i += 2 {
		fmt.Fprintf(&b, "\t%q: %q,\n", bindings[i], bindings[i+1])
	}
	b.WriteString("}\n")
	b.WriteString(refClient)
	return b.String()
}

const refClientImports = `import (
	"bufio"
	"encoding/binary"
	"fmt"
	"io"
	"math"
	"os"
	"os/exec"
	"reflect"
	"runtime"
	"strings"
	"sync"
	"testing"
)

`

// refClient is the replay client compiled into every run tree. Standard
// library only: the run tree is its own module.
const refClient = `
// refArg is one argument of the wasm export: kind 0 i32, 1 i64, 2 f32,
// 3 f64; ptr marks an address into the memory image (rebased by the worker).
type refArg struct {
	kind uint8
	ptr  bool
	bits uint64
}

func rI32(v int32) refArg   { return refArg{kind: 0, bits: uint64(uint32(v))} }
func rI64(v int64) refArg   { return refArg{kind: 1, bits: uint64(v)} }
func rPtr(v int64) refArg   { return refArg{kind: 1, ptr: true, bits: uint64(v)} }
func rF32(v float32) refArg { return refArg{kind: 2, bits: uint64(math.Float32bits(v))} }

// refOut is an output region of the memory image: f32 elements compared to
// a tolerance (the call's, or the region's own when tol is set), or raw
// bytes compared exactly.
type refOut struct {
	off, n int
	exact  bool
	tol    float64
}

func outF32(off, n int) refOut                 { return refOut{off: off, n: n} }
func outF32Tol(off, n int, tol float64) refOut { return refOut{off: off, n: n, tol: tol} }
func outBytes(off, n int) refOut               { return refOut{off: off, n: n, exact: true} }

// Tolerances for the asm-vs-C-body comparison, per kernel family. A
// difference is measured relative to the scale of the output region (its
// largest magnitude on either side, floor 1), not to the element it occurs
// in: the repack GEMMs subtract two large float sums, so an output that
// nearly cancels carries the fold-order difference of the sums that produced
// it. Both sides accumulate the integer part of a quantized dot exactly and
// differ only in the order of the float folds; the FHM attention body
// accumulates V in f16 registers on purpose (the native NEON path's VKQ16),
// which the f32 C body does not. Measured on arm64 with the pinned llama.cpp
// (see the gate logs, "max rel diff"): dots up to 1.7e-5 (q4_1; the rest
// below 1e-6), repack GEMM/GEMV up to a few 1e-5 of the output scale, f32
// GEMM and f16 mad bit-identical, f16 dot and soft_max/swiglu about 1e-7,
// f32 attention below 5e-6, and the f16 V accumulator of the FHM attention
// body up to 1e-2 (the f16 rounding of every scale and add over a
// 301-position accumulation; its S and M are f32 on both sides and stay at
// the f32 bound). A layout or semantics change moves outputs by O(1), so
// each bound sits well above the measured noise and far below any real
// drift; the FHM body's own gate holds its V within one f16 ulp of a
// float64 reference, so its precision is checked there, not here.
const (
	refTolDot     = 1e-4
	refTolGemm    = 1e-4
	refTolF32     = 1e-5
	refTolExp     = 1e-5
	refTolAttn    = 1e-4
	refTolAttnF16 = 5e-2
)

// refResult is what the export returned, when it returns a value.
type refResult struct {
	has bool
	f64 float64
	i64 int64
}

var (
	refMu     sync.Mutex
	refStart  sync.Once
	refIn     io.WriteCloser
	refOutR   *bufio.Reader
	refErr    error
	refWorker *exec.Cmd
)

func refConnect() error {
	refStart.Do(func() {
		cmd := exec.Command("node", "--no-warnings", refScript, refWasm)
		cmd.Stderr = os.Stderr
		in, err := cmd.StdinPipe()
		if err != nil {
			refErr = err
			return
		}
		out, err := cmd.StdoutPipe()
		if err != nil {
			refErr = err
			return
		}
		if err := cmd.Start(); err != nil {
			refErr = fmt.Errorf("start kernel-diff worker: %w", err)
			return
		}
		refIn, refOutR, refWorker = in, bufio.NewReaderSize(out, 1<<20), cmd
	})
	return refErr
}

// refSymbol names the Go symbol behind a kernel func value, e.g. "GemvKernel".
func refSymbol(kernel any) string {
	name := runtime.FuncForPC(reflect.ValueOf(kernel).Pointer()).Name()
	if i := strings.LastIndexByte(name, '.'); i >= 0 {
		name = name[i+1:]
	}
	return name
}

// refCall runs export on the worker with image as the memory contents and
// returns the image after the call and the export's result.
func refCall(export string, args []refArg, fixups []int, image []byte) ([]byte, refResult, error) {
	if err := refConnect(); err != nil {
		return nil, refResult{}, err
	}
	refMu.Lock()
	defer refMu.Unlock()
	var req []byte
	req = binary.LittleEndian.AppendUint32(req, uint32(len(export)))
	req = append(req, export...)
	req = binary.LittleEndian.AppendUint32(req, uint32(len(args)))
	for _, a := range args {
		var spec [16]byte
		spec[0] = a.kind
		if a.ptr {
			spec[1] = 1
		}
		binary.LittleEndian.PutUint64(spec[8:], a.bits)
		req = append(req, spec[:]...)
	}
	req = binary.LittleEndian.AppendUint32(req, uint32(len(fixups)))
	for _, f := range fixups {
		req = binary.LittleEndian.AppendUint64(req, uint64(f))
	}
	req = binary.LittleEndian.AppendUint64(req, uint64(len(image)))
	req = append(req, image...)
	if _, err := refIn.Write(req); err != nil {
		return nil, refResult{}, fmt.Errorf("kernel-diff worker: write: %w", err)
	}
	status, err := refOutR.ReadByte()
	if err != nil {
		return nil, refResult{}, fmt.Errorf("kernel-diff worker: no response: %w", err)
	}
	if status != 0 {
		var n [4]byte
		if _, err := io.ReadFull(refOutR, n[:]); err != nil {
			return nil, refResult{}, err
		}
		msg := make([]byte, binary.LittleEndian.Uint32(n[:]))
		if _, err := io.ReadFull(refOutR, msg); err != nil {
			return nil, refResult{}, err
		}
		return nil, refResult{}, fmt.Errorf("kernel-diff worker: %s: %s", export, msg)
	}
	var head [24]byte
	if _, err := io.ReadFull(refOutR, head[:]); err != nil {
		return nil, refResult{}, err
	}
	var res refResult
	if head[0] != 0 {
		res.has = true
		bits := binary.LittleEndian.Uint64(head[8:])
		if head[1] == 1 {
			res.i64 = int64(bits)
		} else {
			res.f64 = math.Float64frombits(bits)
		}
	}
	n := binary.LittleEndian.Uint64(head[16:])
	if n != uint64(len(image)) {
		return nil, refResult{}, fmt.Errorf("kernel-diff worker: image length %d, sent %d", n, len(image))
	}
	after := make([]byte, n)
	if _, err := io.ReadFull(refOutR, after); err != nil {
		return nil, refResult{}, err
	}
	return after, res, nil
}

func refF32(mem []byte, off int) float32 {
	return math.Float32frombits(binary.LittleEndian.Uint32(mem[off:]))
}

// refCheck replays the kernel call (args, fixups) on the C body with the
// memory image as it was BEFORE the assembly ran (before), and compares the
// C body's output image with the assembly's (after): every byte outside outs
// must be identical, f32 outputs must agree within tol relative to the
// region's scale (its largest magnitude on either side, floor 1), exact
// outputs byte for byte. Returns the C body's result value for the caller to
// compare when the kernel returns one. A no-op when the run tree was
// generated without llama.wasm.
func refCheck(t *testing.T, kernel any, before, after []byte, args []refArg, fixups []int, outs []refOut, tol float64) refResult {
	t.Helper()
	if !refEnabled {
		return refResult{}
	}
	sym := refSymbol(kernel)
	export, ok := refExports[sym]
	if !ok {
		t.Fatalf("wasm differential: no export bound to kernel symbol %q (add the binding to the gate's writeRunTree call)", sym)
	}
	wasm, res, err := refCall(export, args, fixups, before)
	if err != nil {
		t.Fatalf("wasm differential: %v", err)
	}
	inOut := func(off int) (refOut, bool) {
		for _, o := range outs {
			if off >= o.off && off < o.off+o.n {
				return o, true
			}
		}
		return refOut{}, false
	}
	for i := range after {
		if after[i] == wasm[i] {
			continue
		}
		if _, ok := inOut(i); !ok {
			t.Fatalf("%s: C body and asm body differ outside the declared outputs at byte %d: asm %#02x, C %#02x", export, i, after[i], wasm[i])
		}
	}
	maxRel := 0.0
	for _, o := range outs {
		if o.exact {
			for i := o.off; i < o.off+o.n; i++ {
				if after[i] != wasm[i] {
					t.Fatalf("%s: output byte %d (offset %d in the region at %d): asm %#02x, C %#02x", export, i, i-o.off, o.off, after[i], wasm[i])
				}
			}
			continue
		}
		scale := 1.0
		for i := 0; i+4 <= o.n; i += 4 {
			a, c := float64(refF32(after, o.off+i)), float64(refF32(wasm, o.off+i))
			if !math.IsNaN(a) && !math.IsInf(a, 0) {
				scale = math.Max(scale, math.Abs(a))
			}
			if !math.IsNaN(c) && !math.IsInf(c, 0) {
				scale = math.Max(scale, math.Abs(c))
			}
		}
		for i := 0; i+4 <= o.n; i += 4 {
			a, c := refF32(after, o.off+i), refF32(wasm, o.off+i)
			if math.IsNaN(float64(a)) && math.IsNaN(float64(c)) || a == c {
				continue
			}
			rel := math.Abs(float64(a)-float64(c)) / scale
			if rel > maxRel {
				maxRel = rel
			}
			bound := tol
			if o.tol != 0 {
				bound = o.tol
			}
			if rel > bound {
				t.Fatalf("%s: f32 output %d (offset %d): asm %v, C %v, diff %.3g of the region's scale %.3g > %.3g", export, i/4, o.off+i, a, c, rel, scale, bound)
			}
		}
	}
	if maxRel > 0 {
		t.Logf("%s: max rel diff asm vs C body %.3g", export, maxRel)
	}
	if f, err := os.OpenFile(refRecord, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o644); err == nil {
		fmt.Fprintln(f, export)
		f.Close()
	}
	return res
}
`

// TestMain enforces the differential in -require-llama-wasm mode: the wasm
// and node must be present, and after the run every export with a body for
// this host's architecture must have been compared at least once.
func TestMain(m *testing.M) {
	flag.Parse()
	if *requireLlamaWasm {
		if st := ref(); !st.enabled {
			fmt.Fprintf(os.Stderr, "kernel differential required but unavailable: %s\n", st.reason)
			os.Exit(1)
		}
	}
	code := m.Run()
	if code == 0 && *requireLlamaWasm && ref().enabled {
		var missing []string
		for _, k := range Overrides().Kernels {
			for _, b := range k.Bodies {
				if b.Arch == runtime.GOARCH && !refCompared[k.Export] {
					missing = append(missing, k.Export)
					break
				}
			}
		}
		if len(missing) > 0 {
			sort.Strings(missing)
			fmt.Fprintf(os.Stderr, "kernel differential: %d export(s) with a %s body were never compared against the C body: %s\n",
				len(missing), runtime.GOARCH, strings.Join(missing, " "))
			code = 1
		} else {
			fmt.Fprintf(os.Stderr, "kernel differential: all %d %s exports compared against the C body\n", len(refCompared), runtime.GOARCH)
		}
	}
	os.Exit(code)
}
