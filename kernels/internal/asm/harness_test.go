package asm

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
)

// wrap renders a body the way wasm2go's assembly-override wrapper does
// (wasm2go docs/assembly-overrides.md): the TEXT header, the prologue that
// loads the linear-memory base and size into the contract registers,
// the body, and the ovr_oob epilogue. The tests' mockModule keeps the
// memory-size pointer at offset 0 and the memory base at offset 8, and
// the epilogue calls the test's trapstub.
func wrap(arch, sym string, frame, argBytes int, feature, body string) string {
	var b strings.Builder
	fmt.Fprintf(&b, "TEXT ·%s(SB), $%d-%d\n\tNO_LOCAL_POINTERS\n", sym, frame, argBytes)
	switch arch {
	case "arm64":
		b.WriteString("\tMOVD\tm+0(FP), R0\n\tMOVD\t0(R0), R21\n\tMOVD\t(R21), R21\n\tMOVD\t8(R0), R20\n")
	case "amd64":
		b.WriteString("\tMOVQ\tm+0(FP), AX\n\tMOVQ\t0(AX), R15\n\tMOVQ\t(R15), R15\n\tMOVQ\t8(AX), R14\n")
	}
	b.WriteString(strings.TrimRight(body, "\n"))
	b.WriteString("\novr_oob:\n")
	if arch == "amd64" && feature != "sse4" {
		b.WriteString("\tVZEROUPPER\n")
	}
	b.WriteString("\tCALL\t·trapstub(SB)\n\tRET\n\n")
	return b.String()
}

// trapstub is the test stand-in for the module's out-of-bounds trap: it
// faults, which the run tests observe as a crash rather than a wrong
// answer.
func trapstub(arch string) string {
	if arch == "amd64" {
		return "\nTEXT ·trapstub(SB), NOSPLIT, $0-0\n\tMOVQ $0, AX\n\tMOVQ AX, (AX)\n\tRET\n"
	}
	return "\nTEXT ·trapstub(SB), NOSPLIT, $0-0\n\tMOVD $0, R0\n\tMOVD R0, (R0)\n\tRET\n"
}

// writeRunTree lays out a temporary Go test package: the assembled
// kernels, the run sources and the run test.
func writeRunTree(t *testing.T, dir, module, arch, kernelAsm, runSrc, runTest string) {
	t.Helper()
	files := map[string]string{
		"go.mod": "module " + module + "\n\ngo 1.25.0\n",
		"kernel_" + arch + ".s": "//go:build " + arch + "\n\n#include \"textflag.h\"\n#include \"funcdata.h\"\n\n" +
			kernelAsm + trapstub(arch),
		"run.go":      runSrc,
		"run_test.go": runTest,
	}
	for name, content := range files {
		if err := os.WriteFile(filepath.Join(dir, name), []byte(content), 0o644); err != nil {
			t.Fatal(err)
		}
	}
}

// runArm64Gate assembles and links the tree for arm64 on every host and
// executes runName on arm64 hosts.
func runArm64Gate(t *testing.T, dir, pkg, runName, diag string) {
	t.Helper()
	bin := filepath.Join(dir, "gate.test")
	build := exec.Command("go", "test", "-c", "-o", bin, pkg)
	build.Dir = dir
	build.Env = append(os.Environ(), "GOARCH=arm64")
	if out, err := build.CombinedOutput(); err != nil {
		t.Fatalf("arm64 assemble/link failed: %v\n%s\n--- asm ---\n%s", err, out, diag)
	}
	if runtime.GOARCH != "arm64" {
		t.Skipf("assembled+linked OK; skipping arm64 execution on %s/%s host", runtime.GOOS, runtime.GOARCH)
	}
	cmd := exec.Command(bin, "-test.run", runName, "-test.v")
	cmd.Dir = dir
	if out, err := cmd.CombinedOutput(); err != nil {
		t.Fatalf("arm64 execution failed: %v\n%s\n--- asm ---\n%s", err, out, diag)
	}
	t.Logf("arm64 execution:")
}

// runAmd64Gate assembles and links the tree for amd64 on every host and
// executes runName when the host has AVX2.
func runAmd64Gate(t *testing.T, dir, pkg, runName, diag string) {
	t.Helper()
	bin := filepath.Join(dir, "gate.test")
	build := exec.Command("go", "test", "-c", "-o", bin, pkg)
	build.Dir = dir
	build.Env = append(os.Environ(), "GOARCH=amd64")
	if out, err := build.CombinedOutput(); err != nil {
		t.Fatalf("amd64 assemble/link failed: %v\n%s\n--- asm ---\n%s", err, out, diag)
	}
	if runtime.GOARCH != "amd64" || !hostHasAVX2(t) {
		t.Skipf("assembled+linked OK; skipping execution (GOARCH=%s, avx2=%v)", runtime.GOARCH, hostHasAVX2(t))
	}
	cmd := exec.Command(bin, "-test.run", runName, "-test.v")
	cmd.Dir = dir
	if out, err := cmd.CombinedOutput(); err != nil {
		t.Fatalf("amd64 execution failed: %v\n%s", err, out)
	}
}

func hostHasAVX2(t *testing.T) bool {
	t.Helper()
	switch runtime.GOOS {
	case "linux":
		data, err := os.ReadFile("/proc/cpuinfo")
		return err == nil && strings.Contains(string(data), " avx2")
	case "darwin":
		out, err := exec.Command("sysctl", "-n", "hw.optional.avx2_0").Output()
		return err == nil && strings.TrimSpace(string(out)) == "1"
	}
	return false
}

func hostHasVNNI(t *testing.T) bool {
	t.Helper()
	if runtime.GOOS != "linux" {
		return false
	}
	data, err := os.ReadFile("/proc/cpuinfo")
	return err == nil && strings.Contains(string(data), "avx512_vnni")
}
