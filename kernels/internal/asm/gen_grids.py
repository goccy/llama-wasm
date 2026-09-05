#!/usr/bin/env python3
"""Regenerate grids.go from llama.cpp/ggml/src/ggml-common.h (run from the repo root)."""
import re, subprocess
src = open('llama.cpp/ggml/src/ggml-common.h').read()
commit = subprocess.check_output(['git', '-C', 'llama.cpp', 'rev-parse', '--short', 'HEAD']).decode().strip()
TABLES = (('iq3xxs_grid', 'uint32_t', 'uint32', 'iq3xxsGrid'), ('iq3s_grid', 'uint32_t', 'uint32', 'iq3sGrid'),
          ('iq2xxs_grid', 'uint64_t', 'uint64', 'iq2xxsGrid'), ('iq2xs_grid', 'uint64_t', 'uint64', 'iq2xsGrid'),
          ('iq2s_grid', 'uint64_t', 'uint64', 'iq2sGrid'), ('iq1s_grid', 'uint64_t', 'uint64', 'iq1sGrid'),
          ('ksigns_iq2xs', 'uint8_t', 'uint8', 'ksignsIQ2XS'))
out = ['// Code generated from llama.cpp/ggml/src/ggml-common.h (llama.cpp %s) by' % commit,
       '// kernels/internal/asm/gen_grids.py; DO NOT EDIT. The i-quant codebooks the',
       '// dot kernels gather from: each entry packs the magnitudes of four (u32) or',
       '// eight (u64) quants; ksignsIQ2XS maps a 7-bit sign code to its 8 sign bits',
       '// (the eighth is the parity of the seven).', '', 'package asm', '']
for name, ctype, gotype, goname in TABLES:
    m = re.search(r'GGML_TABLE_BEGIN\(%s, %s, (\w+)\)(.*?)GGML_TABLE_END\(\)' % (ctype, name), src, re.S)
    vals = [v.strip() for v in re.sub(r'//.*', '', m.group(2)).replace('\n', ' ').split(',') if v.strip()]
    out.append('var %s = [%d]%s{' % (goname, len(vals), gotype))
    per = 8 if gotype == 'uint32' else (4 if gotype == 'uint64' else 16)
    for i in range(0, len(vals), per):
        out.append('\t' + ', '.join(vals[i:i + per]) + ',')
    out += ['}', '']
open('kernels/internal/asm/grids.go', 'w').write('\n'.join(out))
