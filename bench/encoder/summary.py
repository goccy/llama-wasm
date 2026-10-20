"""Tabulate the encoder benchmark against llama-bench.

Usage: summary.py <encoder.json> <native.json> [<title>]

encoder.json is the -json output of bench/encoder (go-llama on the
bundle); native.json is llama-bench -o json run with the same token and
thread counts (-embd 1 -n 0). Prints a Markdown table of tokens/s and the
go/native ratio per (threads, tokens), appended to GITHUB_STEP_SUMMARY
when set."""
import json
import os
import sys

enc = json.load(open(sys.argv[1]))
nat = json.load(open(sys.argv[2]))
title = sys.argv[3] if len(sys.argv) > 3 else "encoder"
native = {(r["n_threads"], r["n_prompt"]): r["avg_ts"] for r in nat if r.get("n_gen", 0) == 0}
lines = [f"### {title}", "", "| threads | tokens | go-llama tok/s | native tok/s | go/native |", "|---:|---:|---:|---:|---:|"]
for r in enc:
    key = (r["threads"], r["tokens"])
    n = native.get(key)
    ratio = f"{r['avg_tok_s'] / n:.2f}" if n else "-"
    lines.append(f"| {r['threads']} | {r['tokens']} | {r['avg_tok_s']:.0f} | {n:.0f} | {ratio} |" if n else
                 f"| {r['threads']} | {r['tokens']} | {r['avg_tok_s']:.0f} | - | - |")
out = "\n".join(lines) + "\n"
print(out)
if os.environ.get("GITHUB_STEP_SUMMARY"):
    with open(os.environ["GITHUB_STEP_SUMMARY"], "a") as f:
        f.write(out + "\n")
