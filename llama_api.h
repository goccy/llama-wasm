/* llama_api.h — thin llama.cpp embedding API exported to wasm / Go.
 *
 * This is the ONLY surface wasmify exports from libllama. llama.cpp's full API
 * stays internal; Go callers see just these functions. Pinned against the
 * llama.cpp the `llama.cpp` submodule pins, built for wasm32-wasip1 with
 * wasm exception handling (llama.cpp throws) and -msimd128.
 *
 * Conventions, matching the sibling wasmify projects:
 *
 *   - Handles are opaque uint64 values (the address of the heap-allocated
 *     state). A model handle and a context handle are independent: one model
 *     can back several contexts, which is how llama.cpp is meant to be used.
 *     Zero is the failure / null handle.
 *   - String INPUTS are `const char*` plus an EXPLICIT length — never strlen —
 *     so a prompt containing an embedded NUL crosses the bridge intact.
 *   - String OUTPUTS are `std::string`, which the bridge generator returns as
 *     a Go string. Structured results are JSON so one call carries a whole
 *     result without a per-field export.
 *   - Errors are returned, never thrown across the boundary: a call that can
 *     fail returns a JSON object with `"ok"` and, when false, `"error"`.
 *     llama.cpp's own exceptions are caught at this boundary.
 *
 * Threading model: a context is driven from one thread at a time. Everything
 * a host needs WHILE a call is running is therefore exposed as an address in
 * linear memory rather than as a second entry point — a host that has
 * translated this wasm to native code cannot enter it twice, but it can
 * always read and write linear memory: stopping a generation
 * (llama_ctx_interrupt_addr) and watching a model load
 * (llama_model_load_progress_addr) are single aligned words, each with one
 * writer. Anything larger than a word goes the other way, as a call OUT of
 * the guest on the generating thread — see llama_wasm::token_sink.
 */
#ifndef LLAMA_WASM_LLAMA_API_H
#define LLAMA_WASM_LLAMA_API_H

#include <cstdint>
#include <string>

/* ---------------------------------------------------------------- backend */

/* Initialize the ggml backend registry. Idempotent; called automatically by
 * llama_model_load, so an embedder normally never calls it. */
void llama_wasm_init();

/* Free process-wide backend state. After this every handle is invalid. */
void llama_wasm_free();

/* JSON describing the build: llama.cpp version, the ggml backends compiled in,
 * and whether this wasm was built with SIMD / threads. Diagnostics only. */
std::string llama_wasm_build_info();

/* ------------------------------------------------------------------ model */

/* Load a GGUF model from `path` and return an opaque handle (0 on failure;
 * call llama_wasm_last_error for the reason).
 *
 * `n_gpu_layers` is accepted and ignored — a wasm build has no GPU backend —
 * so callers can pass a config through unchanged.
 *
 * `use_mmap` is likewise accepted for API symmetry: WASI has no usable mmap,
 * so the loader always reads the file. Progress is reported through the
 * progress flag described at llama_model_load_progress_addr. */
uint64_t llama_model_load(const char *path, uint32_t path_len,
                          int32_t n_gpu_layers, int32_t use_mmap);

/* Free a model. Contexts created from it must be freed first. */
void llama_model_free(uint64_t model);

/* JSON metadata for a loaded model: architecture, parameter count, context
 * length, embedding dimension, layer/head counts, rope type, vocabulary size,
 * and the chat template when the GGUF carries one. */
std::string llama_model_info(uint64_t model);

/* Address, in linear memory, of a float the loader updates with its progress
 * (0.0 .. 1.0) while llama_model_load runs. A host thread can poll it to drive
 * a progress bar. Valid for the lifetime of the wasm instance. */
uint64_t llama_model_load_progress_addr();

/* ---------------------------------------------------------------- context */

/* Create a context over `model`. `params_json` carries the context
 * parameters; absent fields take llama.cpp's defaults:
 *
 *   n_ctx           0 = the model's training context length
 *   n_batch         logical batch size
 *   n_ubatch        physical batch size
 *   n_threads       0 = 1; a single-threaded wasm build clamps to 1
 *   embeddings      non-zero puts the context in embedding mode
 *   rope_freq_base  RoPE base frequency override (0 = model default)
 *   rope_freq_scale RoPE frequency scaling override (0 = model default)
 */
uint64_t llama_ctx_new(uint64_t model, const char *params_json,
                       uint32_t params_json_len);

/* Free a context. */
void llama_ctx_free(uint64_t ctx);

/* Address of this context's interrupt flag (a uint32 in linear memory).
 * Writing a non-zero value from another thread makes the running
 * llama_ctx_generate stop at its next token and return what it has, with
 * `"interrupted":true`. The generation loop clears the flag when it starts. */
uint64_t llama_ctx_interrupt_addr(uint64_t ctx);

/* Rebuild and attach the context's ggml threadpool. An instance forked
   from a snapshot inherits the memory image of a context whose pool
   references worker threads of the snapshot builder; those threads do not
   exist in this process, so the next decode (or the join inside
   llama_ctx_free) would wait forever. Call this right after forking: it
   creates a fresh pool with n_threads workers (poll=0, as llama_ctx_new)
   and attaches it, ABANDONING the inherited pool struct -- its memory is
   shared snapshot pages and its dead threads cannot be joined. n_threads
   <= 1 detaches instead. Returns {"ok":true} or an error object. */
std::string llama_ctx_attach_threadpool(uint64_t ctx, uint32_t n_threads);

/* -------------------------------------------------------------- tokenizer */

/* Tokenize `text` and return JSON `{"ok":true,"tokens":[..]}`.
 * `add_special` adds BOS/EOS per the model's convention; `parse_special`
 * lets special-token text (e.g. "<|im_start|>") tokenize as that token. */
std::string llama_tokenize(uint64_t model, const char *text, uint32_t text_len,
                           int32_t add_special, int32_t parse_special);

/* Render tokens (a JSON array of ints) back to text:
 * `{"ok":true,"text":"..."}`. */
std::string llama_detokenize(uint64_t model, const char *tokens_json,
                             uint32_t tokens_json_len, int32_t render_special);

/* The text piece a single token renders to, as JSON `{"ok":true,"text":".."}`.
 * Byte-level tokens can render to invalid UTF-8 on their own; the caller is
 * expected to accumulate pieces. */
std::string llama_token_to_piece(uint64_t model, int32_t token,
                                 int32_t render_special);

/* ------------------------------------------------------------- generation */

/* Sink for the text a generation produces, implemented by the host.
 *
 * The generation loop calls on_piece once per decoded token, synchronously,
 * from inside llama_ctx_generate. That is deliberately not a buffer the host
 * polls: a host that has translated this wasm to native code runs the guest
 * on one of its own threads, so anything it read WHILE generating would be
 * read without synchronisation. A call out of the generation loop reaches the
 * host on the very thread that is generating, so there is nothing to
 * synchronise.
 *
 * Pieces concatenate to the "text" field of the result, except that a stop
 * string is delivered as it is decoded and only afterwards trimmed from the
 * returned text.
 *
 * Abstract on purpose: wasmify emits a Go-implementable interface for a class
 * with an unimplemented pure virtual. */
namespace llama_wasm {

class token_sink {
public:
    virtual ~token_sink() = default;
    virtual void on_piece(const std::string &piece) = 0;
};

} // namespace llama_wasm

/* Run generation and return JSON:
 *
 *   {"ok":true,"text":"...","tokens":[..],"n_prompt":N,"n_cached":N,
 *    "n_decoded":N,
 *    "stop_reason":"eos"|"length"|"stop"|"interrupted","interrupted":bool,
 *    "timings":{"prompt_ms":f,"decode_ms":f}}
 *
 * `prompt` is tokenized with add_special=true. `params_json` carries the
 * sampling configuration; every field is optional:
 *
 *   {"n_predict":int,          // -1 = until EOS or context end
 *    "temperature":float, "top_k":int, "top_p":float, "min_p":float,
 *    "typical_p":float, "repeat_penalty":float, "repeat_last_n":int,
 *    "presence_penalty":float, "frequency_penalty":float,
 *    "seed":uint, "grammar":"...", "stop":["..",".."],
 *    "mirostat":int,            // 0 off, 1 v1, 2 v2; replaces the
 *    "mirostat_tau":float,      // truncation samplers when set
 *    "mirostat_eta":float,
 *    "ignore_eos":int,          // non-zero: end-of-generation tokens
 *                               // are excluded from sampling
 *    "cache_prompt":int,        // non-zero: treat the prompt as the whole
 *                               // intended context, keep the longest prefix
 *                               // already in the KV cache and decode only
 *                               // the rest (n_cached reports the reuse).
 *                               // Off, the prompt appends at the cache's
 *                               // current end (Eval-prefill continuation).
 *    "logit_bias":[[token,bias],..]} // added to those tokens' logits;
 *                               // -inf forbids a token outright
 *
 * `sink`, when non-null, receives each piece as it is decoded — see
 * llama_wasm::token_sink. The result is the same either way. */
std::string llama_ctx_generate(uint64_t ctx, const char *prompt,
                               uint32_t prompt_len, const char *params_json,
                               uint32_t params_json_len,
                               llama_wasm::token_sink *sink);


/* llama_ctx_generate_speculative is llama_ctx_generate accelerated by a
 * draft context over a smaller model with the SAME vocabulary: the draft
 * proposes up to `n_draft` greedy tokens per round (0 = a default) and the
 * target verifies them in one batch, emitting only tokens its own sampler
 * chain picked — the output distribution is exactly the target's, the
 * draft only shifts decode work into larger batches.
 *
 * Self-contained: both contexts' caches restart from the prompt. The
 * response is llama_ctx_generate's plus `"n_drafted"` / `"n_accepted"`,
 * the speculation efficiency counters. */
std::string llama_ctx_generate_speculative(uint64_t ctx, uint64_t draft_ctx,
                                           const char *prompt,
                                           uint32_t prompt_len,
                                           const char *params_json,
                                           uint32_t params_json_len,
                                           int32_t n_draft,
                                           llama_wasm::token_sink *sink);

/* -------------------------------------------------------------------- lora */

/* Load a LoRA adapter GGUF for `model`. Returns an adapter handle, or 0
 * (see llama_wasm_last_error). The adapter must not outlive its model. */
uint64_t llama_lora_load(uint64_t model, const char *path, uint32_t path_len);

/* Free a loaded adapter. Adapters still set on a context must be cleared
 * (llama_ctx_lora_set with an empty array) first. */
void llama_lora_free(uint64_t adapter);

/* Set the FULL adapter configuration of a context: `adapters_json` is
 * `[[adapter_handle,scale],...]`; an empty array clears every adapter. */
std::string llama_ctx_lora_set(uint64_t ctx, const char *adapters_json,
                               uint32_t adapters_json_len);

/* Apply the model's chat template to `messages_json`
 * (`[{"role":"user","content":"hi"}, ...]`) and return the prompt string:
 * `{"ok":true,"prompt":"..."}`. `add_assistant` appends the generation
 * prefix. When the GGUF carries no template, `template_override` is used;
 * when both are absent the call fails. */
std::string llama_chat_apply_template(uint64_t model, const char *messages_json,
                                      uint32_t messages_json_len,
                                      const char *template_override,
                                      uint32_t template_override_len,
                                      int32_t add_assistant);

/* ------------------------------------------------------------- embeddings */

/* Embed `text` with a context created with embeddings=1 and return
 * `{"ok":true,"embedding":[..],"n_embd":N}`. `normalize` applies L2
 * normalisation (2 = euclidean, 0 = none), matching llama.cpp's convention. */
/**
 * llama_ctx_score computes the teacher-forced negative log-likelihood of
 * `text`: tokenize (add_special, parse_special), decode once with logits at
 * every predicting position, and sum -log softmax(logits_i)[token_{i+1}].
 * Returns `{"ok":true,"n_tokens":N,"n_scored":N-1,"nll":X}`. The float-
 * tolerant compatibility gate compares this against native llama.cpp
 * perplexity on the same text.
 */
std::string llama_ctx_score(uint64_t ctx, const char *text, uint32_t text_len);

std::string llama_ctx_embed(uint64_t ctx, const char *text, uint32_t text_len,
                            int32_t normalize);

/* Embed from token ids (a JSON array of ints) instead of text — the
 * token-level twin of llama_ctx_embed, same response shape. */
std::string llama_ctx_embed_tokens(uint64_t ctx, const char *tokens_json,
                                   uint32_t tokens_json_len, int32_t normalize);

/* ------------------------------------------------------------- kv / state */

/* Decode `text` into the context's KV cache without sampling anything —
 * prompt prefill for a later llama_ctx_generate, or plain evaluation.
 * Positions continue from the cache's current end; llama_ctx_reset
 * starts over. Returns `{"ok":true,"n_tokens":N,"n_past":N}` where
 * n_past is the total sequence length now cached. */
std::string llama_ctx_eval(uint64_t ctx, const char *text, uint32_t text_len,
                           int32_t add_special, int32_t parse_special);

/* Drop the context's KV cache so the next generation starts fresh. */
void llama_ctx_reset(uint64_t ctx);

/* Serialize the context state (KV cache + RNG) into the context's state
 * buffer and return `{"ok":true,"addr":N,"size":N}` — the caller reads that
 * many bytes at that linear-memory address. The buffer stays valid until the
 * next state call on this context. The blob also carries the prefix-history
 * tokens in a bridge envelope, so a restored context composes with the
 * generate params' cache_prompt without a rebuild. */
std::string llama_ctx_state_save(uint64_t ctx);

/* Restore a context state previously produced by llama_ctx_state_save.
 * `data` carries the serialized bytes (the bridge copies them into
 * linear memory; they may contain NUL bytes). A blob from this bridge also
 * restores the prefix history for cache_prompt; a bare llama-state blob
 * (an older bridge's) restores with the history invalid, so the next
 * cache_prompt generate rebuilds from scratch. */
std::string llama_ctx_state_load(uint64_t ctx, const char *data,
                                 uint32_t size);

/* ------------------------------------------------------------------ error */

/* The message for the most recent failed call on this thread, or "" when the
 * last call succeeded. Calls that return JSON carry their own "error" field;
 * this exists for the handle-returning calls, which can only signal 0. */
std::string llama_wasm_last_error();

#endif /* LLAMA_WASM_LLAMA_API_H */
