// Command encoder times one encoder pass (prompt processing into a
// CLS/mean embedding) through the go-llama engine on the bundle this
// module replaces in, for a set of token counts and thread counts, and
// prints tokens per second per setting. Pair it with llama-bench
// (-embd 1 -n 0 -p <tokens> -t <threads>) on the same machine for the
// native reference.
package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	llama "github.com/goccy/go-llama"
)

type result struct {
	Model   string  `json:"model"`
	Threads int     `json:"threads"`
	Tokens  int     `json:"tokens"`
	AvgMs   float64 `json:"avg_ms"`
	BestMs  float64 `json:"best_ms"`
	AvgTokS float64 `json:"avg_tok_s"`
}

func main() {
	model := flag.String("model", "", "GGUF file")
	threads := flag.String("threads", "1,8", "comma-separated thread counts")
	tokens := flag.String("tokens", "32,128,512", "comma-separated token counts")
	reps := flag.Int("reps", 5, "timed repetitions per setting (after 2 warm-ups)")
	jsonOut := flag.String("json", "", "write results as a JSON array to this file")
	flag.Parse()
	if *model == "" {
		fmt.Fprintln(os.Stderr, "encoder: -model is required")
		os.Exit(2)
	}
	dir, err := filepath.Abs(filepath.Dir(*model))
	if err != nil {
		fail(err)
	}
	inst, err := llama.New(llama.WithPreopenDir(dir))
	if err != nil {
		fail(err)
	}
	m, err := inst.LoadModel(filepath.Base(*model))
	if err != nil {
		fail(err)
	}
	defer m.Close()
	var results []result
	for _, nt := range ints(*threads) {
		ctx, err := m.NewContext(llama.ContextParams{NCtx: 1024, NBatch: 1024, NUBatch: 1024, NThreads: uint32(nt), Embeddings: true})
		if err != nil {
			fail(err)
		}
		for _, n := range ints(*tokens) {
			toks := make([]int32, n)
			toks[0], toks[n-1] = 1, 2
			for i := 1; i < n-1; i++ {
				toks[i] = int32(1000 + (i*37)%50000)
			}
			for i := 0; i < 2; i++ {
				if _, err := ctx.EmbedTokens(toks, false); err != nil {
					fail(err)
				}
			}
			best := time.Hour
			var total time.Duration
			for i := 0; i < *reps; i++ {
				t0 := time.Now()
				if _, err := ctx.EmbedTokens(toks, false); err != nil {
					fail(err)
				}
				d := time.Since(t0)
				total += d
				if d < best {
					best = d
				}
			}
			avg := total / time.Duration(*reps)
			r := result{Model: filepath.Base(*model), Threads: nt, Tokens: n,
				AvgMs: float64(avg) / 1e6, BestMs: float64(best) / 1e6, AvgTokS: float64(n) / avg.Seconds()}
			results = append(results, r)
			fmt.Printf("threads=%d tokens=%4d  avg %8.1f ms  best %8.1f ms  %7.0f tok/s\n", nt, n, r.AvgMs, r.BestMs, r.AvgTokS)
		}
		ctx.Close()
	}
	if *jsonOut != "" {
		b, _ := json.MarshalIndent(results, "", " ")
		if err := os.WriteFile(*jsonOut, b, 0o644); err != nil {
			fail(err)
		}
	}
}

func ints(s string) []int {
	var out []int
	for _, f := range strings.Split(s, ",") {
		v, err := strconv.Atoi(strings.TrimSpace(f))
		if err != nil {
			fail(fmt.Errorf("bad integer list %q: %w", s, err))
		}
		out = append(out, v)
	}
	return out
}

func fail(err error) {
	fmt.Fprintln(os.Stderr, "encoder:", err)
	os.Exit(1)
}
