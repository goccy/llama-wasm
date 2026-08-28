/* llama_api.cc — implementation of the thin llama.cpp embedding API.
 *
 * Everything llama.cpp can throw is caught at this boundary: an exception
 * must never cross into the generated Go, so each entry point that can fail
 * either returns a JSON object carrying "ok"/"error" or returns the null
 * handle and records the message for llama_wasm_last_error.
 */

#include "llama_api.h"

#include "llama.h"
#include "ggml-cpu.h"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <string>
#include <vector>

namespace {

/* ------------------------------------------------------------- json output
 *
 * A hand-rolled writer rather than a JSON library: the payloads are small and
 * fully under our control, and it keeps the wasm free of another dependency.
 * Only the escaping needs care, so that is the only non-trivial part.
 */

void json_escape(std::string &out, const char *s, size_t n) {
    out.push_back('"');
    for (size_t i = 0; i < n; i++) {
        unsigned char c = (unsigned char) s[i];
        switch (c) {
            case '"':  out += "\\\""; break;
            case '\\': out += "\\\\"; break;
            case '\n': out += "\\n";  break;
            case '\r': out += "\\r";  break;
            case '\t': out += "\\t";  break;
            case '\b': out += "\\b";  break;
            case '\f': out += "\\f";  break;
            default:
                if (c < 0x20) {
                    char buf[8];
                    snprintf(buf, sizeof(buf), "\\u%04x", c);
                    out += buf;
                } else {
                    // Bytes >= 0x20 pass through, including UTF-8 continuation
                    // bytes. A partial multi-byte sequence (byte-level tokens
                    // can produce one) stays as-is; the Go side accumulates
                    // pieces before interpreting them as text.
                    out.push_back((char) c);
                }
        }
    }
    out.push_back('"');
}

std::string json_str(const std::string &s) {
    std::string out;
    json_escape(out, s.data(), s.size());
    return out;
}

std::string b64_encode(const std::string &in) {
    static const char tab[] =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    std::string out;
    out.reserve(((in.size() + 2) / 3) * 4);
    size_t i = 0;
    for (; i + 3 <= in.size(); i += 3) {
        uint32_t v = (uint8_t) in[i] << 16 | (uint8_t) in[i + 1] << 8 | (uint8_t) in[i + 2];
        out.push_back(tab[v >> 18]);
        out.push_back(tab[(v >> 12) & 63]);
        out.push_back(tab[(v >> 6) & 63]);
        out.push_back(tab[v & 63]);
    }
    if (i + 1 == in.size()) {
        uint32_t v = (uint8_t) in[i] << 16;
        out.push_back(tab[v >> 18]);
        out.push_back(tab[(v >> 12) & 63]);
        out += "==";
    } else if (i + 2 == in.size()) {
        uint32_t v = (uint8_t) in[i] << 16 | (uint8_t) in[i + 1] << 8;
        out.push_back(tab[v >> 18]);
        out.push_back(tab[(v >> 12) & 63]);
        out.push_back(tab[(v >> 6) & 63]);
        out.push_back('=');
    }
    return out;
}

std::string json_num(double v) {
    char buf[64];
    if (v == (double) (long long) v && std::fabs(v) < 1e15) {
        snprintf(buf, sizeof(buf), "%lld", (long long) v);
    } else {
        snprintf(buf, sizeof(buf), "%.9g", v);
    }
    return buf;
}

std::string json_err(const std::string &msg) {
    return "{\"ok\":false,\"error\":" + json_str(msg) + "}";
}

/* --------------------------------------------------------- json input
 *
 * Just enough of a reader for the parameter objects and token arrays this API
 * accepts: object member lookup by key, numbers, booleans, strings and flat
 * arrays. Anything malformed reports failure rather than guessing.
 */

struct JsonReader {
    const char *p;
    const char *end;
    bool ok = true;

    JsonReader(const char *s, size_t n) : p(s), end(s + n) {}

    void ws() {
        while (p < end && (*p == ' ' || *p == '\t' || *p == '\n' || *p == '\r')) p++;
    }
    bool eat(char c) {
        ws();
        if (p < end && *p == c) { p++; return true; }
        return false;
    }
    bool peek(char c) { ws(); return p < end && *p == c; }

    bool str(std::string &out) {
        ws();
        if (p >= end || *p != '"') return ok = false;
        p++;
        out.clear();
        while (p < end && *p != '"') {
            if (*p == '\\' && p + 1 < end) {
                p++;
                switch (*p) {
                    case 'n': out.push_back('\n'); break;
                    case 'r': out.push_back('\r'); break;
                    case 't': out.push_back('\t'); break;
                    case 'b': out.push_back('\b'); break;
                    case 'f': out.push_back('\f'); break;
                    case 'u': {
                        if (p + 4 >= end) return ok = false;
                        unsigned cp = 0;
                        for (int i = 1; i <= 4; i++) {
                            char c = p[i];
                            cp <<= 4;
                            if (c >= '0' && c <= '9')      cp |= unsigned(c - '0');
                            else if (c >= 'a' && c <= 'f') cp |= unsigned(c - 'a' + 10);
                            else if (c >= 'A' && c <= 'F') cp |= unsigned(c - 'A' + 10);
                            else return ok = false;
                        }
                        p += 4;
                        // UTF-8 encode; lone surrogates become U+FFFD, which is
                        // what a strict decoder would substitute anyway.
                        if (cp >= 0xD800 && cp <= 0xDFFF) cp = 0xFFFD;
                        if (cp < 0x80) {
                            out.push_back((char) cp);
                        } else if (cp < 0x800) {
                            out.push_back((char) (0xC0 | (cp >> 6)));
                            out.push_back((char) (0x80 | (cp & 0x3F)));
                        } else {
                            out.push_back((char) (0xE0 | (cp >> 12)));
                            out.push_back((char) (0x80 | ((cp >> 6) & 0x3F)));
                            out.push_back((char) (0x80 | (cp & 0x3F)));
                        }
                        break;
                    }
                    default: out.push_back(*p);
                }
                p++;
                continue;
            }
            out.push_back(*p++);
        }
        if (p >= end) return ok = false;
        p++; // closing quote
        return true;
    }

    bool num(double &out) {
        ws();
        char *stop = nullptr;
        // The buffer is not NUL-terminated in general; copy the numeric run.
        const char *s = p;
        while (p < end && (*p == '-' || *p == '+' || *p == '.' || *p == 'e' ||
                           *p == 'E' || (*p >= '0' && *p <= '9'))) {
            p++;
        }
        std::string tmp(s, size_t(p - s));
        if (tmp.empty()) return ok = false;
        out = strtod(tmp.c_str(), &stop);
        return true;
    }

    // Skips one value of any kind, leaving p just past it.
    bool skip() {
        ws();
        if (p >= end) return ok = false;
        if (*p == '"') { std::string t; return str(t); }
        if (*p == '{' || *p == '[') {
            char open = *p, close = open == '{' ? '}' : ']';
            int depth = 0;
            while (p < end) {
                if (*p == '"') { std::string t; if (!str(t)) return false; continue; }
                if (*p == open) depth++;
                else if (*p == close) { depth--; p++; if (depth == 0) return true; continue; }
                p++;
            }
            return ok = false;
        }
        while (p < end && *p != ',' && *p != '}' && *p != ']') p++;
        return true;
    }
};

// find_member positions a reader just after `"key":` inside the object in
// `json`, returning false when the key is absent (not an error).
bool find_member(const char *json, size_t len, const char *key, JsonReader &out) {
    JsonReader r(json, len);
    if (!r.eat('{')) return false;
    if (r.eat('}')) return false;
    for (;;) {
        std::string k;
        if (!r.str(k)) return false;
        if (!r.eat(':')) return false;
        if (k == key) { out = r; return true; }
        if (!r.skip()) return false;
        if (r.eat(',')) continue;
        return false;
    }
}

bool opt_num(const char *json, size_t len, const char *key, double &out) {
    JsonReader r(nullptr, 0);
    if (!find_member(json, len, key, r)) return false;
    return r.num(out);
}

bool opt_str(const char *json, size_t len, const char *key, std::string &out) {
    JsonReader r(nullptr, 0);
    if (!find_member(json, len, key, r)) return false;
    return r.str(out);
}

bool opt_str_array(const char *json, size_t len, const char *key,
                   std::vector<std::string> &out) {
    JsonReader r(nullptr, 0);
    if (!find_member(json, len, key, r)) return false;
    if (!r.eat('[')) return false;
    if (r.eat(']')) return true;
    for (;;) {
        std::string s;
        if (!r.str(s)) return false;
        out.push_back(s);
        if (r.eat(',')) continue;
        return r.eat(']');
    }
}

/* ------------------------------------------------------------ handle state */

struct ModelState {
    llama_model *model = nullptr;
};

struct CtxState {
    llama_context *ctx = nullptr;
    llama_model   *model = nullptr;
    // interrupt is polled by the generation loop; its ADDRESS is handed to the
    // host so another thread can stop a running generation.
    uint32_t interrupt = 0;
    bool       generating = false;
    // state_buf backs llama_ctx_state_save: the host reads it straight out of
    // linear memory, so it must outlive the call.
    std::vector<uint8_t> state_buf;
    // threadpool is the persistent ggml worker pool attached to the context
    // in a threads build. Without one, ggml creates and destroys a disposable
    // pool — n_threads-1 thread spawns plus joins — for EVERY graph, i.e.
    // for every generated token. The pool runs with poll=0 (see ctx_new):
    // workers park as soon as a graph completes and are woken per graph,
    // which is cheap on the goroutine host and keeps idle contexts from
    // spinning on cores the decoding context needs.
    struct ggml_threadpool *threadpool = nullptr;
    // hist mirrors the tokens whose KV entries are materialized in the
    // context, in position order — what a cache_prompt generate matches the
    // new prompt against to skip re-decoding a shared prefix. Every path that
    // decodes maintains it; a path that mutates the cache in a way this
    // bookkeeping does not model (state_load, LoRA swaps, speculative
    // decoding, score/embed scratch use) flips hist_valid instead, and the
    // next cache_prompt generate clears the cache and rebuilds from scratch.
    std::vector<llama_token> hist;
    bool hist_valid = true;
};

// Process-wide bits. The error slot is thread_local so a wasi-threads agent
// does not clobber another thread's message. It is a POD buffer rather than a
// std::string on purpose: a thread_local with a non-trivial destructor pulls
// in __cxa_thread_atexit, which wasi-libc does not provide in the
// single-threaded sysroot. Messages are short; longer ones truncate.
constexpr size_t kErrorMax = 512;
thread_local char g_last_error[kErrorMax] = {0};
float g_load_progress = 0.0f;
bool  g_backend_ready = false;

void set_error(const std::string &msg) {
    const size_t n = std::min(msg.size(), kErrorMax - 1);
    memcpy(g_last_error, msg.data(), n);
    g_last_error[n] = '\0';
}

ModelState *model_of(uint64_t h) { return reinterpret_cast<ModelState *>(h); }
CtxState   *ctx_of(uint64_t h)   { return reinterpret_cast<CtxState *>(h); }

bool load_progress_cb(float progress, void * /*user_data*/) {
    g_load_progress = progress;
    return true; // never abort from here; cancellation is a host concern
}

} // namespace

/* ---------------------------------------------------------------- backend */

void llama_wasm_init() {
    if (g_backend_ready) return;
    llama_backend_init();
    // Silence llama.cpp's own logging: a wasm build writes it to stderr, which
    // the host would have to demultiplex from real output. Diagnostics travel
    // through the JSON results instead.
    llama_log_set([](ggml_log_level, const char *, void *) {}, nullptr);
    g_backend_ready = true;
}

void llama_wasm_free() {
    if (!g_backend_ready) return;
    llama_backend_free();
    g_backend_ready = false;
}

std::string llama_wasm_build_info() {
    std::string out = "{\"ok\":true";
    out += ",\"simd\":";
#if defined(__wasm_simd128__)
    out += "true";
#else
    out += "false";
#endif
    out += ",\"threads\":";
#if defined(_REENTRANT) || defined(__wasi_thread__)
    out += "true";
#else
    out += "false";
#endif
    out += ",\"exceptions\":";
#if defined(__WASM_EXCEPTIONS__)
    out += "true";
#else
    out += "false";
#endif
    out += ",\"max_devices\":" + json_num((double) llama_max_devices());
    out += "}";
    return out;
}

/* ------------------------------------------------------------------ model */

uint64_t llama_model_load(const char *path, uint32_t path_len,
                          int32_t /*n_gpu_layers*/, int32_t /*use_mmap*/) {
    llama_wasm_init();
    set_error("");
    g_load_progress = 0.0f;
    try {
        std::string p(path, path_len);
        llama_model_params mp = llama_model_default_params();
        mp.n_gpu_layers   = 0;                     // no GPU backend in wasm
        mp.load_mode      = LLAMA_LOAD_MODE_NONE;  // WASI has no usable mmap
        mp.progress_callback           = load_progress_cb;
        mp.progress_callback_user_data = nullptr;

        llama_model *m = llama_model_load_from_file(p.c_str(), mp);
        if (m == nullptr) {
            set_error("failed to load model: " + p);
            return 0;
        }
        auto *st = new ModelState();
        st->model = m;
        g_load_progress = 1.0f;
        return reinterpret_cast<uint64_t>(st);
    } catch (const std::exception &e) {
        set_error(std::string("load: ") + e.what());
        return 0;
    } catch (...) {
        set_error("load: unknown error");
        return 0;
    }
}

void llama_model_free(uint64_t model) {
    ModelState *st = model_of(model);
    if (st == nullptr) return;
    if (st->model != nullptr) llama_model_free(st->model);
    delete st;
}

std::string llama_model_info(uint64_t model) {
    ModelState *st = model_of(model);
    if (st == nullptr) return json_err("null model handle");
    try {
        const llama_vocab *vocab = llama_model_get_vocab(st->model);
        char desc[256] = {0};
        llama_model_desc(st->model, desc, sizeof(desc));

        std::string out = "{\"ok\":true";
        out += ",\"desc\":" + json_str(desc);
        out += ",\"n_params\":" + json_num((double) llama_model_n_params(st->model));
        out += ",\"size_bytes\":" + json_num((double) llama_model_size(st->model));
        out += ",\"n_ctx_train\":" + json_num(llama_model_n_ctx_train(st->model));
        out += ",\"n_embd\":" + json_num(llama_model_n_embd(st->model));
        out += ",\"n_layer\":" + json_num(llama_model_n_layer(st->model));
        out += ",\"n_head\":" + json_num(llama_model_n_head(st->model));
        out += ",\"n_head_kv\":" + json_num(llama_model_n_head_kv(st->model));
        out += ",\"n_vocab\":" + json_num(llama_vocab_n_tokens(vocab));
        out += ",\"has_encoder\":" + std::string(llama_model_has_encoder(st->model) ? "true" : "false");
        out += ",\"has_decoder\":" + std::string(llama_model_has_decoder(st->model) ? "true" : "false");
        // Vocab landmarks; -1 when the model defines none
        // (LLAMA_TOKEN_NULL), so callers need no sentinel knowledge.
        out += ",\"bos_token\":" + json_num(llama_vocab_bos(vocab));
        out += ",\"eos_token\":" + json_num(llama_vocab_eos(vocab));
        out += ",\"add_bos\":" + std::string(llama_vocab_get_add_bos(vocab) ? "true" : "false");
        const char *tmpl = llama_model_chat_template(st->model, nullptr);
        out += ",\"chat_template\":" + json_str(tmpl != nullptr ? tmpl : "");
        out += "}";
        return out;
    } catch (const std::exception &e) {
        return json_err(std::string("model_info: ") + e.what());
    } catch (...) {
        return json_err("model_info: unknown error");
    }
}

uint64_t llama_model_load_progress_addr() {
    return (uint64_t) (uintptr_t) &g_load_progress;
}

/* ------------------------------------------------------------------- lora */

uint64_t llama_lora_load(uint64_t model, const char *path, uint32_t path_len) {
    set_error("");
    ModelState *ms = model_of(model);
    if (ms == nullptr) {
        set_error("null model handle");
        return 0;
    }
    try {
        const std::string p(path, path_len);
        llama_adapter_lora *a = llama_adapter_lora_init(ms->model, p.c_str());
        if (a == nullptr) {
            set_error("lora_load: failed to load " + p);
            return 0;
        }
        return reinterpret_cast<uint64_t>(a);
    } catch (const std::exception &e) {
        set_error(std::string("lora_load: ") + e.what());
        return 0;
    } catch (...) {
        set_error("lora_load: unknown error");
        return 0;
    }
}

void llama_lora_free(uint64_t adapter) {
    if (adapter == 0) return;
    llama_adapter_lora_free(reinterpret_cast<llama_adapter_lora *>(adapter));
}

/* Set the FULL adapter configuration of a context: `adapters_json` is
 * `[[adapter_handle,scale],...]`, and an empty array clears every
 * adapter. Set-everything rather than add/remove because that is
 * llama.cpp's own API shape (llama_set_adapters_lora). */
std::string llama_ctx_lora_set(uint64_t ctx, const char *adapters_json,
                               uint32_t adapters_json_len) {
    CtxState *st = ctx_of(ctx);
    if (st == nullptr) return json_err("null context handle");
    try {
        std::vector<llama_adapter_lora *> adapters;
        std::vector<float> scales;
        JsonReader r(adapters_json, adapters_json_len);
        if (!r.eat('[')) return json_err("lora_set: expected a JSON array");
        if (!r.eat(']')) {
            for (;;) {
                double handle = 0, scale = 0;
                if (!r.eat('[') || !r.num(handle) || !r.eat(',') ||
                    !r.num(scale) || !r.eat(']')) {
                    return json_err("lora_set: expected [adapter,scale] pairs");
                }
                auto *a = reinterpret_cast<llama_adapter_lora *>((uint64_t) handle);
                if (a == nullptr) return json_err("lora_set: null adapter handle");
                adapters.push_back(a);
                scales.push_back((float) scale);
                if (r.eat(',')) continue;
                if (!r.eat(']')) return json_err("lora_set: unterminated array");
                break;
            }
        }
        if (llama_set_adapters_lora(st->ctx, adapters.data(), adapters.size(),
                                    scales.data()) != 0) {
            return json_err("lora_set: engine rejected the adapter set");
        }
        // Cached KV was computed with the previous adapter set; a later
        // cache_prompt generate must not splice new logits onto it.
        st->hist.clear();
        st->hist_valid = false;
        return "{\"ok\":true}";
    } catch (const std::exception &e) {
        return json_err(std::string("lora_set: ") + e.what());
    } catch (...) {
        return json_err("lora_set: unknown error");
    }
}

/* ---------------------------------------------------------------- context */

uint64_t llama_ctx_new(uint64_t model, const char *params_json,
                       uint32_t params_json_len) {
    set_error("");
    ModelState *ms = model_of(model);
    if (ms == nullptr) {
        set_error("null model handle");
        return 0;
    }
    try {
        const char *json = params_json;
        const size_t len = params_json_len;
        llama_context_params cp = llama_context_default_params();
        double d;
        if (opt_num(json, len, "n_ctx", d)    && d != 0) cp.n_ctx    = (uint32_t) d;
        if (opt_num(json, len, "n_batch", d)  && d != 0) cp.n_batch  = (uint32_t) d;
        if (opt_num(json, len, "n_ubatch", d) && d != 0) cp.n_ubatch = (uint32_t) d;
        // n_seq_max > 1 turns on the unified KV cache: n_ctx stays the TOTAL
        // cell budget shared by all sequences (not per-sequence slices), and
        // llama_memory_seq_cp shares cells instead of copying them — which
        // is what llama_ctx_score_choices' batched scoring relies on, its
        // sequences all sharing the stem prefix.
        if (opt_num(json, len, "n_seq_max", d) && d > 1) {
            // llama.cpp rejects n_seq_max > LLAMA_MAX_SEQ (256) with a
            // throw; refuse here with a precise message instead.
            if (d > 256) {
                set_error("n_seq_max must be <= 256");
                return 0;
            }
            cp.n_seq_max  = (uint32_t) d;
            cp.kv_unified = true;
        }
        // A single-threaded wasm build has no usable pthread_create: ggml
        // asserts if asked for more than one thread, so clamp rather than
        // trap. A threads build honours the request.
        int32_t n_threads = 0;
        if (opt_num(json, len, "n_threads", d)) n_threads = (int32_t) d;
#if defined(_REENTRANT)
        cp.n_threads       = n_threads != 0 ? n_threads : 1;
        cp.n_threads_batch = cp.n_threads;
#else
        (void) n_threads;
        cp.n_threads       = 1;
        cp.n_threads_batch = 1;
#endif
        if (opt_num(json, len, "embeddings", d)) cp.embeddings = d != 0;
        // 0 keeps the model's own RoPE configuration, llama.cpp's
        // convention for these two.
        if (opt_num(json, len, "rope_freq_base", d))  cp.rope_freq_base  = (float) d;
        if (opt_num(json, len, "rope_freq_scale", d)) cp.rope_freq_scale = (float) d;

        llama_context *c = llama_init_from_model(ms->model, cp);
#if defined(_REENTRANT)
        struct ggml_threadpool *tp = nullptr;
        if (c != nullptr && cp.n_threads > 1) {
            struct ggml_threadpool_params tpp =
                ggml_threadpool_params_default(cp.n_threads);
            // No polling between graphs: on the goroutine host a parked
            // worker wakes in microseconds (channel notify), while the default
            // poll budget spins 1024*128*50 rounds after every graph and, with
            // one pool per context, steals cores from the context that is
            // actually decoding.
            tpp.poll = 0;
            tp = ggml_threadpool_new(&tpp);
            if (tp != nullptr) {
                llama_attach_threadpool(c, tp, tp);
            }
        }
#endif
        if (c == nullptr) {
            set_error("failed to create context");
            return 0;
        }
        auto *st = new CtxState();
        st->ctx   = c;
        st->model = ms->model;
#if defined(_REENTRANT)
        st->threadpool = tp;
#endif
        return reinterpret_cast<uint64_t>(st);
    } catch (const std::exception &e) {
        set_error(std::string("ctx_new: ") + e.what());
        return 0;
    } catch (...) {
        set_error("ctx_new: unknown error");
        return 0;
    }
}

void llama_ctx_free(uint64_t ctx) {
    CtxState *st = ctx_of(ctx);
    if (st == nullptr) return;
    if (st->ctx != nullptr) llama_free(st->ctx);
#if defined(_REENTRANT)
    // Free the pool after the context: llama_free may still touch it.
    if (st->threadpool != nullptr) ggml_threadpool_free(st->threadpool);
#endif
    delete st;
}

uint64_t llama_ctx_interrupt_addr(uint64_t ctx) {
    CtxState *st = ctx_of(ctx);
    if (st == nullptr) return 0;
    return (uint64_t) (uintptr_t) &st->interrupt;
}

std::string llama_ctx_attach_threadpool(uint64_t ctx, uint32_t n_threads) {
    CtxState *st = ctx_of(ctx);
    if (st == nullptr) return json_err("null context handle");
    if (st->ctx == nullptr) return json_err("attach_threadpool: context is closed");
#if defined(_REENTRANT)
    struct ggml_threadpool *tp = nullptr;
    if (n_threads > 1) {
        struct ggml_threadpool_params tpp =
            ggml_threadpool_params_default((int) n_threads);
        // No polling between graphs, matching llama_ctx_new: a parked worker
        // wakes in microseconds on the goroutine host.
        tpp.poll = 0;
        tp = ggml_threadpool_new(&tpp);
        if (tp == nullptr) return json_err("attach_threadpool: ggml_threadpool_new failed");
    }
    if (tp != nullptr) {
        llama_attach_threadpool(st->ctx, tp, tp);
    } else {
        llama_detach_threadpool(st->ctx);
    }
    // Abandon, never free, the previous pool: in a forked instance its
    // worker threads belong to the snapshot builder and cannot be joined;
    // the struct itself lives in shared snapshot pages.
    st->threadpool = tp;
#else
    (void) n_threads;
    st->threadpool = nullptr;
#endif
    return "{\"ok\":true}";
}

/* -------------------------------------------------------------- tokenizer */

namespace {

bool tokenize_text(const llama_vocab *vocab, const std::string &text,
                   bool add_special, bool parse_special,
                   std::vector<llama_token> &out, std::string &err) {
    const int n = -llama_tokenize(vocab, text.c_str(), (int32_t) text.size(),
                                  nullptr, 0, add_special, parse_special);
    if (n < 0) {
        err = "tokenize: negative count";
        return false;
    }
    out.resize((size_t) n);
    const int got = llama_tokenize(vocab, text.c_str(), (int32_t) text.size(),
                                   out.data(), (int32_t) out.size(),
                                   add_special, parse_special);
    if (got < 0) {
        err = "tokenize: failed";
        return false;
    }
    out.resize((size_t) got);
    return true;
}

std::string piece_of(const llama_vocab *vocab, llama_token tok, bool special) {
    char buf[256];
    int n = llama_token_to_piece(vocab, tok, buf, (int32_t) sizeof(buf), 0, special);
    if (n < 0) {
        std::vector<char> big((size_t) (-n));
        n = llama_token_to_piece(vocab, tok, big.data(), (int32_t) big.size(), 0, special);
        if (n < 0) return "";
        return std::string(big.data(), (size_t) n);
    }
    return std::string(buf, (size_t) n);
}

} // namespace

std::string llama_tokenize(uint64_t model, const char *text, uint32_t text_len,
                           int32_t add_special, int32_t parse_special) {
    ModelState *ms = model_of(model);
    if (ms == nullptr) return json_err("null model handle");
    try {
        const llama_vocab *vocab = llama_model_get_vocab(ms->model);
        std::vector<llama_token> toks;
        std::string err;
        if (!tokenize_text(vocab, std::string(text, text_len), add_special != 0,
                           parse_special != 0, toks, err)) {
            return json_err(err);
        }
        std::string out = "{\"ok\":true,\"tokens\":[";
        for (size_t i = 0; i < toks.size(); i++) {
            if (i != 0) out.push_back(',');
            out += json_num(toks[i]);
        }
        out += "]}";
        return out;
    } catch (const std::exception &e) {
        return json_err(std::string("tokenize: ") + e.what());
    } catch (...) {
        return json_err("tokenize: unknown error");
    }
}

std::string llama_detokenize(uint64_t model, const char *tokens_json,
                             uint32_t tokens_json_len, int32_t render_special) {
    ModelState *ms = model_of(model);
    if (ms == nullptr) return json_err("null model handle");
    try {
        const llama_vocab *vocab = llama_model_get_vocab(ms->model);
        JsonReader r(tokens_json, tokens_json_len);
        if (!r.eat('[')) return json_err("detokenize: expected a JSON array");
        std::string text;
        if (!r.eat(']')) {
            for (;;) {
                double v = 0;
                if (!r.num(v)) return json_err("detokenize: bad token value");
                text += piece_of(vocab, (llama_token) v, render_special != 0);
                if (r.eat(',')) continue;
                if (!r.eat(']')) return json_err("detokenize: unterminated array");
                break;
            }
        }
        return "{\"ok\":true,\"text\":" + json_str(text) + "}";
    } catch (const std::exception &e) {
        return json_err(std::string("detokenize: ") + e.what());
    } catch (...) {
        return json_err("detokenize: unknown error");
    }
}

std::string llama_token_to_piece(uint64_t model, int32_t token,
                                 int32_t render_special) {
    ModelState *ms = model_of(model);
    if (ms == nullptr) return json_err("null model handle");
    try {
        const llama_vocab *vocab = llama_model_get_vocab(ms->model);
        const std::string piece = piece_of(vocab, (llama_token) token, render_special != 0);
        // A byte-fallback token holds a PARTIAL UTF-8 sequence, which
        // a JSON string cannot carry losslessly; b64 carries the raw
        // bytes, text stays for older consumers.
        return "{\"ok\":true,\"text\":" + json_str(piece) +
               ",\"b64\":\"" + b64_encode(piece) + "\"}";
    } catch (const std::exception &e) {
        return json_err(std::string("token_to_piece: ") + e.what());
    } catch (...) {
        return json_err("token_to_piece: unknown error");
    }
}

/* ------------------------------------------------------------- generation */

namespace {

struct SamplingParams {
    int32_t n_predict         = -1;
    float   temperature       = 0.8f;
    int32_t top_k             = 40;
    float   top_p             = 0.95f;
    float   min_p             = 0.05f;
    float   typical_p         = 1.0f;
    float   repeat_penalty    = 1.0f;
    int32_t repeat_last_n     = 64;
    float   presence_penalty  = 0.0f;
    float   frequency_penalty = 0.0f;
    uint32_t seed             = LLAMA_DEFAULT_SEED;
    int32_t mirostat          = 0;    // 0 off, 1 v1, 2 v2
    float   mirostat_tau      = 5.0f;
    float   mirostat_eta      = 0.1f;
    bool    ignore_eos        = false;
    // cache_prompt opts a generate into prompt-prefix reuse: the prompt is
    // treated as the WHOLE intended context, the longest prefix already in
    // the KV cache is kept, the divergent tail is dropped and only the rest
    // is decoded. Off by default because the default contract is positional
    // continuation (Eval prefill + Generate).
    bool    cache_prompt      = false;
    std::vector<llama_logit_bias> logit_bias;
    std::string grammar;
    std::vector<std::string> stop;
};

// opt_bias_array parses `"key":[[token,bias],...]` — the wire form of
// logit biases. A malformed array fails the parse and leaves `out`
// empty rather than half-filled.
bool opt_bias_array(const char *json, size_t len, const char *key,
                    std::vector<llama_logit_bias> &out) {
    JsonReader r(nullptr, 0);
    if (!find_member(json, len, key, r)) return false;
    std::vector<llama_logit_bias> parsed;
    if (!r.eat('[')) return false;
    if (r.eat(']')) { out = parsed; return true; }
    for (;;) {
        double tok = 0, bias = 0;
        if (!r.eat('[') || !r.num(tok) || !r.eat(',') || !r.num(bias) ||
            !r.eat(']')) {
            return false;
        }
        parsed.push_back({(llama_token) tok, (float) bias});
        if (r.eat(',')) continue;
        if (!r.eat(']')) return false;
        break;
    }
    out = parsed;
    return true;
}

SamplingParams parse_params(const char *json, size_t len) {
    SamplingParams sp;
    double d;
    if (opt_num(json, len, "n_predict", d))         sp.n_predict         = (int32_t) d;
    if (opt_num(json, len, "temperature", d))       sp.temperature       = (float) d;
    if (opt_num(json, len, "top_k", d))             sp.top_k             = (int32_t) d;
    if (opt_num(json, len, "top_p", d))             sp.top_p             = (float) d;
    if (opt_num(json, len, "min_p", d))             sp.min_p             = (float) d;
    if (opt_num(json, len, "typical_p", d))         sp.typical_p         = (float) d;
    if (opt_num(json, len, "repeat_penalty", d))    sp.repeat_penalty    = (float) d;
    if (opt_num(json, len, "repeat_last_n", d))     sp.repeat_last_n     = (int32_t) d;
    if (opt_num(json, len, "presence_penalty", d))  sp.presence_penalty  = (float) d;
    if (opt_num(json, len, "frequency_penalty", d)) sp.frequency_penalty = (float) d;
    if (opt_num(json, len, "seed", d))              sp.seed              = (uint32_t) d;
    if (opt_num(json, len, "mirostat", d))          sp.mirostat          = (int32_t) d;
    if (opt_num(json, len, "mirostat_tau", d))      sp.mirostat_tau      = (float) d;
    if (opt_num(json, len, "mirostat_eta", d))      sp.mirostat_eta      = (float) d;
    if (opt_num(json, len, "ignore_eos", d))        sp.ignore_eos        = d != 0;
    if (opt_num(json, len, "cache_prompt", d))      sp.cache_prompt      = d != 0;
    opt_bias_array(json, len, "logit_bias", sp.logit_bias);
    opt_str(json, len, "grammar", sp.grammar);
    opt_str_array(json, len, "stop", sp.stop);
    return sp;
}

llama_sampler *build_sampler(const llama_vocab *vocab, const SamplingParams &sp) {
    llama_sampler_chain_params cp = llama_sampler_chain_default_params();
    cp.no_perf = true;
    llama_sampler *chain = llama_sampler_chain_init(cp);
    const int32_t n_vocab = llama_vocab_n_tokens(vocab);

    // Logit biases run before everything else, exactly as in
    // llama.cpp's common sampler. ignore_eos is spelled as -inf biases
    // on every end-of-generation token, so those tokens can never be
    // sampled — the loop's EOG check then simply never fires.
    std::vector<llama_logit_bias> biases = sp.logit_bias;
    if (sp.ignore_eos) {
        for (llama_token t = 0; t < n_vocab; t++) {
            if (llama_vocab_is_eog(vocab, t)) {
                biases.push_back({t, -INFINITY});
            }
        }
    }
    if (!biases.empty()) {
        llama_sampler_chain_add(chain,
            llama_sampler_init_logit_bias(n_vocab, (int32_t) biases.size(),
                                          biases.data()));
    }
    if (!sp.grammar.empty()) {
        llama_sampler_chain_add(chain,
            llama_sampler_init_grammar(vocab, sp.grammar.c_str(), "root"));
    }
    if (sp.repeat_penalty != 1.0f || sp.presence_penalty != 0.0f ||
        sp.frequency_penalty != 0.0f) {
        llama_sampler_chain_add(chain,
            llama_sampler_init_penalties(sp.repeat_last_n, sp.repeat_penalty,
                                         sp.frequency_penalty, sp.presence_penalty));
    }
    // Temperature <= 0 means greedy: no truncation samplers, just argmax.
    if (sp.temperature <= 0.0f) {
        llama_sampler_chain_add(chain, llama_sampler_init_greedy());
        return chain;
    }
    // Mirostat controls perplexity dynamically and REPLACES the
    // truncation samplers, matching llama.cpp's common sampler wiring:
    // temperature scaling, then the mirostat sampler (which draws the
    // token itself, so no dist sampler either).
    if (sp.mirostat == 1 || sp.mirostat == 2) {
        llama_sampler_chain_add(chain, llama_sampler_init_temp(sp.temperature));
        if (sp.mirostat == 1) {
            llama_sampler_chain_add(chain,
                llama_sampler_init_mirostat(n_vocab, sp.seed, sp.mirostat_tau,
                                            sp.mirostat_eta, 100));
        } else {
            llama_sampler_chain_add(chain,
                llama_sampler_init_mirostat_v2(sp.seed, sp.mirostat_tau,
                                               sp.mirostat_eta));
        }
        return chain;
    }
    if (sp.top_k > 0)                        llama_sampler_chain_add(chain, llama_sampler_init_top_k(sp.top_k));
    if (sp.typical_p > 0.0f && sp.typical_p < 1.0f)
                                             llama_sampler_chain_add(chain, llama_sampler_init_typical(sp.typical_p, 1));
    if (sp.top_p > 0.0f && sp.top_p < 1.0f)  llama_sampler_chain_add(chain, llama_sampler_init_top_p(sp.top_p, 1));
    if (sp.min_p > 0.0f)                     llama_sampler_chain_add(chain, llama_sampler_init_min_p(sp.min_p, 1));
    llama_sampler_chain_add(chain, llama_sampler_init_temp(sp.temperature));
    llama_sampler_chain_add(chain, llama_sampler_init_dist(sp.seed));
    return chain;
}

// find_stop looks for the FIRST occurrence of any stop string at or
// after the piece that begins at piece_start — including a match that
// spans the piece boundary — and reports the byte offset the text
// must be cut at. This mirrors llama.cpp's server semantics (cut at
// the first occurrence anywhere), not just a piece-suffix match.
bool find_stop(const std::string &text, const std::vector<std::string> &stops,
               size_t piece_start, size_t &cut) {
    bool found = false;
    for (const auto &s : stops) {
        if (s.empty()) continue;
        const size_t back = s.size() - 1;
        const size_t from = piece_start > back ? piece_start - back : 0;
        const size_t p = text.find(s, from);
        if (p != std::string::npos && (!found || p < cut)) {
            cut = p;
            found = true;
        }
    }
    return found;
}

} // namespace

std::string llama_ctx_generate(uint64_t ctx, const char *prompt,
                               uint32_t prompt_len, const char *params_json,
                               uint32_t params_json_len,
                               llama_wasm::token_sink *sink) {
    CtxState *st = ctx_of(ctx);
    if (st == nullptr) return json_err("null context handle");

    llama_sampler *smpl = nullptr;
    try {
        const SamplingParams sp = parse_params(params_json, params_json_len);
        const llama_vocab *vocab = llama_model_get_vocab(st->model);

        std::vector<llama_token> toks;
        std::string err;
        if (!tokenize_text(vocab, std::string(prompt, prompt_len),
                           /*add_special=*/true, /*parse_special=*/true, toks, err)) {
            return json_err(err);
        }
        const int n_prompt = (int) toks.size();
        if (n_prompt == 0) return json_err("generate: empty prompt");

        const int n_ctx = (int) llama_n_ctx(st->ctx);
        int budget = sp.n_predict < 0 ? n_ctx - n_prompt : sp.n_predict;
        if (budget < 0) budget = 0;

        smpl = build_sampler(vocab, sp);
        st->interrupt = 0;
        st->generating = true;

        std::string text;
        std::vector<llama_token> produced;
        const char *stop_reason = "length";
        bool interrupted = false;

        // Prompt-prefix reuse: keep the longest prefix of the prompt whose
        // KV entries already exist, drop everything the cache holds beyond
        // it, and decode only the rest. At least the final prompt token is
        // always re-decoded — sampling needs its logits.
        int n_keep = 0;
        if (sp.cache_prompt) {
            if (!st->hist_valid) {
                llama_memory_clear(llama_get_memory(st->ctx), true);
                st->hist.clear();
                st->hist_valid = true;
            }
            const int lim = std::min((int) st->hist.size(), n_prompt - 1);
            while (n_keep < lim && st->hist[n_keep] == toks[n_keep]) n_keep++;
            llama_memory_seq_rm(llama_get_memory(st->ctx), 0, n_keep, -1);
            st->hist.resize(n_keep);
        }

        // Decode the prompt in n_batch-sized chunks: llama_decode rejects
        // a batch larger than the context's n_batch, and splitting is the
        // CALLER's job (native llama.cpp CLIs do the same). The interrupt
        // flag is honoured between chunks so a long prompt can be stopped.
        const int nb = (int) llama_n_batch(st->ctx);
        int n_decoded = 0;
        bool prompt_ok = true;
        const auto t_start = std::chrono::steady_clock::now();
        for (int off = n_keep; off < n_prompt && !interrupted; off += nb) {
            if (st->interrupt != 0) {
                interrupted = true;
                stop_reason = "interrupted";
                break;
            }
            const int take = std::min(nb, n_prompt - off);
            if (llama_decode(st->ctx, llama_batch_get_one(toks.data() + off, take)) != 0) {
                prompt_ok = false;
                break;
            }
            if (st->hist_valid) {
                st->hist.insert(st->hist.end(), toks.begin() + off,
                                toks.begin() + off + take);
            }
        }
        if (!prompt_ok) {
            st->generating = false;
            llama_sampler_free(smpl);
            return json_err("generate: decode failed");
        }
        const auto t_prompt = std::chrono::steady_clock::now();
        for (int i = 0; i < budget && !interrupted; i++) {
            const llama_token tok = llama_sampler_sample(smpl, st->ctx, -1);
            if (llama_vocab_is_eog(vocab, tok)) {
                stop_reason = "eos";
                break;
            }
            produced.push_back(tok);
            n_decoded++;
            const std::string piece = piece_of(vocab, tok, /*special=*/false);
            const size_t piece_start = text.size();
            text += piece;
            if (sink != nullptr) sink->on_piece(piece);

            size_t cut = 0;
            if (find_stop(text, sp.stop, piece_start, cut)) {
                text.resize(cut);
                stop_reason = "stop";
                break;
            }
            if (i + 1 == budget) {
                break; // budget spent: skip the decode whose logits no one samples
            }
            if (st->interrupt != 0) {
                interrupted = true;
                stop_reason = "interrupted";
                break;
            }
            if (llama_decode(st->ctx, llama_batch_get_one(&produced.back(), 1)) != 0) {
                st->generating = false;
                llama_sampler_free(smpl);
                return json_err("generate: decode failed");
            }
            if (st->hist_valid) st->hist.push_back(produced.back());
        }
        st->generating = false;
        llama_sampler_free(smpl);
        smpl = nullptr;

        std::string out = "{\"ok\":true";
        out += ",\"text\":" + json_str(text);
        out += ",\"tokens\":[";
        for (size_t i = 0; i < produced.size(); i++) {
            if (i != 0) out.push_back(',');
            out += json_num(produced[i]);
        }
        out += "]";
        out += ",\"n_prompt\":" + json_num(n_prompt);
        out += ",\"n_cached\":" + json_num(n_keep);
        out += ",\"n_decoded\":" + json_num(n_decoded);
        out += ",\"stop_reason\":" + json_str(stop_reason);
        out += ",\"interrupted\":" + std::string(interrupted ? "true" : "false");
        const auto t_end = std::chrono::steady_clock::now();
        const auto ms = [](std::chrono::steady_clock::duration d) {
            return std::chrono::duration<double, std::milli>(d).count();
        };
        out += ",\"timings\":{\"prompt_ms\":" + json_num(ms(t_prompt - t_start)) +
               ",\"decode_ms\":" + json_num(ms(t_end - t_prompt)) + "}";
        out += "}";
        return out;
    } catch (const std::exception &e) {
        st->generating = false;
        if (smpl != nullptr) llama_sampler_free(smpl);
        return json_err(std::string("generate: ") + e.what());
    } catch (...) {
        st->generating = false;
        if (smpl != nullptr) llama_sampler_free(smpl);
        return json_err("generate: unknown error");
    }
}

std::string llama_chat_apply_template(uint64_t model, const char *messages_json,
                                      uint32_t messages_json_len,
                                      const char *template_override,
                                      uint32_t template_override_len,
                                      int32_t add_assistant) {
    ModelState *ms = model_of(model);
    if (ms == nullptr) return json_err("null model handle");
    try {
        std::string tmpl(template_override, template_override_len);
        if (tmpl.empty()) {
            const char *t = llama_model_chat_template(ms->model, nullptr);
            if (t != nullptr) tmpl = t;
        }
        if (tmpl.empty()) {
            return json_err("chat_apply_template: model has no chat template and none was given");
        }

        // Parse [{"role":..,"content":..}, ...]. The strings must outlive the
        // llama_chat_message array, which only holds pointers into them.
        JsonReader r(messages_json, messages_json_len);
        if (!r.eat('[')) return json_err("chat_apply_template: expected a JSON array");
        std::vector<std::string> roles, contents;
        if (!r.eat(']')) {
            for (;;) {
                if (!r.eat('{')) return json_err("chat_apply_template: expected a message object");
                std::string role, content;
                for (;;) {
                    std::string k;
                    if (!r.str(k)) return json_err("chat_apply_template: bad message key");
                    if (!r.eat(':')) return json_err("chat_apply_template: expected ':'");
                    if (k == "role") {
                        if (!r.str(role)) return json_err("chat_apply_template: bad role");
                    } else if (k == "content") {
                        if (!r.str(content)) return json_err("chat_apply_template: bad content");
                    } else if (!r.skip()) {
                        return json_err("chat_apply_template: bad message value");
                    }
                    if (r.eat(',')) continue;
                    if (!r.eat('}')) return json_err("chat_apply_template: unterminated message");
                    break;
                }
                roles.push_back(role);
                contents.push_back(content);
                if (r.eat(',')) continue;
                if (!r.eat(']')) return json_err("chat_apply_template: unterminated array");
                break;
            }
        }

        std::vector<llama_chat_message> msgs;
        msgs.reserve(roles.size());
        for (size_t i = 0; i < roles.size(); i++) {
            msgs.push_back({roles[i].c_str(), contents[i].c_str()});
        }

        size_t cap = 1024;
        for (const auto &c : contents) cap += 2 * c.size() + 64;
        std::vector<char> buf(cap);
        int32_t n = llama_chat_apply_template(tmpl.c_str(), msgs.data(), msgs.size(),
                                              add_assistant != 0, buf.data(),
                                              (int32_t) buf.size());
        if (n < 0) return json_err("chat_apply_template: unsupported template");
        if ((size_t) n > buf.size()) {
            buf.resize((size_t) n);
            n = llama_chat_apply_template(tmpl.c_str(), msgs.data(), msgs.size(),
                                          add_assistant != 0, buf.data(),
                                          (int32_t) buf.size());
            if (n < 0) return json_err("chat_apply_template: unsupported template");
        }
        return "{\"ok\":true,\"prompt\":" + json_str(std::string(buf.data(), (size_t) n)) + "}";
    } catch (const std::exception &e) {
        return json_err(std::string("chat_apply_template: ") + e.what());
    } catch (...) {
        return json_err("chat_apply_template: unknown error");
    }
}

std::string llama_ctx_generate_speculative(uint64_t ctx, uint64_t draft_ctx,
                                           const char *prompt,
                                           uint32_t prompt_len,
                                           const char *params_json,
                                           uint32_t params_json_len,
                                           int32_t n_draft,
                                           llama_wasm::token_sink *sink) {
    CtxState *st = ctx_of(ctx);
    CtxState *ds = ctx_of(draft_ctx);
    if (st == nullptr || ds == nullptr) return json_err("null context handle");
    if (st == ds) return json_err("speculative: target and draft must be distinct contexts");

    llama_sampler *smpl = nullptr;
    llama_sampler *dsmpl = nullptr;
    llama_batch vb = {};
    bool vb_init = false;
    // Every error path funnels through fail() so the samplers, the batch
    // and the generating flag can never leak.
    auto fail = [&](const std::string &msg) {
        st->generating = false;
        if (smpl != nullptr) llama_sampler_free(smpl);
        if (dsmpl != nullptr) llama_sampler_free(dsmpl);
        if (vb_init) llama_batch_free(vb);
        return json_err(msg);
    };
    try {
        const SamplingParams sp = parse_params(params_json, params_json_len);
        const llama_vocab *vocab  = llama_model_get_vocab(st->model);
        const llama_vocab *dvocab = llama_model_get_vocab(ds->model);
        if (llama_vocab_n_tokens(vocab) != llama_vocab_n_tokens(dvocab)) {
            return json_err("speculative: target and draft vocabularies differ");
        }
        if (n_draft <= 0) n_draft = 8;

        std::vector<llama_token> toks;
        std::string err;
        if (!tokenize_text(vocab, std::string(prompt, prompt_len),
                           /*add_special=*/true, /*parse_special=*/true, toks, err)) {
            return json_err(err);
        }
        const int n_prompt = (int) toks.size();
        if (n_prompt == 0) return json_err("generate: empty prompt");

        const int n_ctx = (int) llama_n_ctx(st->ctx);
        int budget = sp.n_predict < 0 ? n_ctx - n_prompt : sp.n_predict;
        if (budget < 0) budget = 0;

        smpl = build_sampler(vocab, sp);
        // The draft always proposes greedily: correctness never depends on
        // it, because every emitted token is sampled by the target's own
        // chain — the draft only decides how much verification batches up.
        llama_sampler_chain_params dcp = llama_sampler_chain_default_params();
        dcp.no_perf = true;
        dsmpl = llama_sampler_chain_init(dcp);
        llama_sampler_chain_add(dsmpl, llama_sampler_init_greedy());

        st->interrupt = 0;
        st->generating = true;

        // Self-contained: both caches restart from the prompt, keeping the
        // two sequences aligned by construction. The acceptance loop edits
        // both caches in ways the prefix-history bookkeeping does not model,
        // so both go invalid until something rebuilds them.
        llama_memory_clear(llama_get_memory(st->ctx), true);
        llama_memory_clear(llama_get_memory(ds->ctx), true);
        st->hist.clear();
        st->hist_valid = false;
        ds->hist.clear();
        ds->hist_valid = false;

        auto prefill = [&](CtxState *cs) -> bool {
            const int nb = (int) llama_n_batch(cs->ctx);
            for (int off = 0; off < n_prompt; off += nb) {
                const int take = std::min(nb, n_prompt - off);
                if (llama_decode(cs->ctx, llama_batch_get_one(toks.data() + off, take)) != 0) {
                    return false;
                }
            }
            return true;
        };
        const auto t_start = std::chrono::steady_clock::now();
        if (!prefill(st) || !prefill(ds)) return fail("generate: decode failed");
        const auto t_prompt = std::chrono::steady_clock::now();

        std::string text;
        std::vector<llama_token> produced;
        const char *stop_reason = "length";
        bool interrupted = false;
        int n_drafted = 0, n_accepted = 0;
        int tpos = n_prompt; // target KV length in tokens
        int dpos = n_prompt; // draft KV length in tokens

        vb = llama_batch_init(n_draft + 1, 0, 1);
        vb_init = true;

        bool done = budget == 0;
        // emit appends one target-sampled token to the result; false means
        // generation must stop here (stop string or budget).
        auto emit = [&](llama_token tok) -> bool {
            produced.push_back(tok);
            const std::string piece = piece_of(vocab, tok, /*special=*/false);
            const size_t piece_start = text.size();
            text += piece;
            if (sink != nullptr) sink->on_piece(piece);
            size_t cut = 0;
            if (find_stop(text, sp.stop, piece_start, cut)) {
                text.resize(cut);
                stop_reason = "stop";
                return false;
            }
            return (int) produced.size() < budget;
        };

        // pending: the last emitted token, in neither KV cache yet. The
        // target decodes it at the head of the next verification batch.
        llama_token pending = 0;
        if (!done) {
            pending = llama_sampler_sample(smpl, st->ctx, -1);
            if (llama_vocab_is_eog(vocab, pending)) {
                stop_reason = "eos";
                done = true;
            } else if (!emit(pending)) {
                done = true;
            }
        }

        while (!done) {
            if (st->interrupt != 0) {
                interrupted = true;
                stop_reason = "interrupted";
                break;
            }
            // Catch the draft up: drop any rejected drafts from its cache,
            // then feed it the pending token.
            if (dpos > tpos) {
                llama_memory_seq_rm(llama_get_memory(ds->ctx), 0, tpos, -1);
                dpos = tpos;
            }
            llama_token feed = pending;
            if (llama_decode(ds->ctx, llama_batch_get_one(&feed, 1)) != 0) {
                return fail("generate: draft decode failed");
            }
            dpos++;

            // Propose up to k greedy continuations. A draft EOG proposal
            // just ends the round early — whether generation ends is the
            // target's call, on its own logits.
            int k = std::min(n_draft, budget - (int) produced.size());
            k = std::min(k, n_ctx - tpos - 1);
            if (k < 0) k = 0;
            std::vector<llama_token> drafts;
            for (int j = 0; j < k; j++) {
                const llama_token d = llama_sampler_sample(dsmpl, ds->ctx, -1);
                if (llama_vocab_is_eog(dvocab, d)) break;
                drafts.push_back(d);
                llama_token dc = d;
                if (llama_decode(ds->ctx, llama_batch_get_one(&dc, 1)) != 0) {
                    return fail("generate: draft decode failed");
                }
                dpos++;
            }
            n_drafted += (int) drafts.size();

            // Verify in ONE target batch: pending + the drafts, logits at
            // every position.
            vb.n_tokens = 1 + (int) drafts.size();
            for (int j = 0; j < vb.n_tokens; j++) {
                vb.token[j]     = j == 0 ? pending : drafts[(size_t) (j - 1)];
                vb.pos[j]       = tpos + j;
                vb.n_seq_id[j]  = 1;
                vb.seq_id[j][0] = 0;
                vb.logits[j]    = true;
            }
            const int base = tpos;
            if (llama_decode(st->ctx, vb) != 0) {
                return fail("generate: decode failed");
            }
            tpos += vb.n_tokens;

            // Walk the verification logits: logits[i] condition on
            // [.., pending, drafts[0..i-1]]. Accept while the target's own
            // sample agrees with the draft; the first disagreement (or the
            // bonus sample past the last draft) becomes the next pending.
            for (size_t i = 0; !done && i <= drafts.size(); i++) {
                const llama_token t = llama_sampler_sample(smpl, st->ctx, (int32_t) i);
                const bool keep = i < drafts.size() && t == drafts[i];
                if (keep) {
                    n_accepted++;
                } else if (i < drafts.size()) {
                    // Rejected from drafts[i] on: the accepted prefix stays,
                    // the tail leaves the target cache.
                    llama_memory_seq_rm(llama_get_memory(st->ctx), 0,
                                        base + 1 + (llama_pos) i, -1);
                    tpos = base + 1 + (int) i;
                }
                if (llama_vocab_is_eog(vocab, t)) {
                    stop_reason = "eos";
                    done = true;
                    break;
                }
                if (!emit(t)) {
                    done = true;
                    break;
                }
                if (!keep) {
                    // The disagreeing sample — or the bonus sample past a
                    // fully accepted run — is the next round's pending.
                    pending = t;
                    break;
                }
            }
        }
        st->generating = false;
        llama_sampler_free(smpl);
        smpl = nullptr;
        llama_sampler_free(dsmpl);
        dsmpl = nullptr;
        llama_batch_free(vb);
        vb_init = false;

        std::string out = "{\"ok\":true";
        out += ",\"text\":" + json_str(text);
        out += ",\"tokens\":[";
        for (size_t i = 0; i < produced.size(); i++) {
            if (i != 0) out.push_back(',');
            out += json_num(produced[i]);
        }
        out += "]";
        out += ",\"n_prompt\":" + json_num(n_prompt);
        out += ",\"n_decoded\":" + json_num((double) produced.size());
        out += ",\"n_drafted\":" + json_num(n_drafted);
        out += ",\"n_accepted\":" + json_num(n_accepted);
        out += ",\"stop_reason\":" + json_str(stop_reason);
        out += ",\"interrupted\":" + std::string(interrupted ? "true" : "false");
        const auto t_end = std::chrono::steady_clock::now();
        const auto ms = [](std::chrono::steady_clock::duration d) {
            return std::chrono::duration<double, std::milli>(d).count();
        };
        out += ",\"timings\":{\"prompt_ms\":" + json_num(ms(t_prompt - t_start)) +
               ",\"decode_ms\":" + json_num(ms(t_end - t_prompt)) + "}";
        out += "}";
        return out;
    } catch (const std::exception &e) {
        return fail(std::string("generate: ") + e.what());
    } catch (...) {
        return fail("generate: unknown error");
    }
}

/* ------------------------------------------------------------------ score */

std::string llama_ctx_score(uint64_t ctx, const char *text, uint32_t text_len) {
    CtxState *st = ctx_of(ctx);
    if (st == nullptr) return json_err("null context handle");
    try {
        const llama_vocab *vocab = llama_model_get_vocab(st->model);
        std::vector<llama_token> toks;
        std::string err;
        if (!tokenize_text(vocab, std::string(text, text_len), true, true, toks, err)) {
            return json_err(err);
        }
        const int n = (int) toks.size();
        if (n < 2) return json_err("score: need at least two tokens");
        const int n_ctx = (int) llama_n_ctx(st->ctx);
        if (n > n_ctx) return json_err("score: text exceeds the context window");

        // Scratch use of the cache: the scored text replaces whatever the
        // prefix-history bookkeeping was tracking.
        llama_memory_clear(llama_get_memory(st->ctx), true);
        st->hist.clear();
        st->hist_valid = false;
        llama_batch batch = llama_batch_init(n, 0, 1);
        for (int i = 0; i < n; i++) {
            batch.token[i]     = toks[i];
            batch.pos[i]       = i;
            batch.n_seq_id[i]  = 1;
            batch.seq_id[i][0] = 0;
            // Logits are needed at every position that PREDICTS a
            // following token (teacher forcing).
            batch.logits[i]    = i + 1 < n;
        }
        batch.n_tokens = n;
        const int rc = llama_decode(st->ctx, batch);
        llama_batch_free(batch);
        if (rc != 0) return json_err("score: decode failed");

        const int n_vocab = llama_vocab_n_tokens(vocab);
        double nll = 0.0;
        for (int i = 0; i + 1 < n; i++) {
            const float *logits = llama_get_logits_ith(st->ctx, i);
            if (logits == nullptr) return json_err("score: no logits");
            float maxv = logits[0];
            for (int v = 1; v < n_vocab; v++) {
                if (logits[v] > maxv) maxv = logits[v];
            }
            double sum = 0.0;
            for (int v = 0; v < n_vocab; v++) {
                sum += std::exp((double) logits[v] - (double) maxv);
            }
            const double logprob =
                (double) logits[toks[i + 1]] - (double) maxv - std::log(sum);
            nll -= logprob;
        }
        std::string out = "{\"ok\":true";
        out += ",\"n_tokens\":" + json_num(n);
        out += ",\"n_scored\":" + json_num(n - 1);
        out += ",\"nll\":" + json_num(nll);
        out += "}";
        return out;
    } catch (const std::exception &e) {
        return json_err(std::string("score: ") + e.what());
    } catch (...) {
        return json_err("score: unknown error");
    }
}

namespace {

// log_softmax_at returns log P(token | logits) with the usual max-shift for
// numerical stability.
double log_softmax_at(const float *logits, int n_vocab, llama_token token) {
    float maxv = logits[0];
    for (int v = 1; v < n_vocab; v++) {
        if (logits[v] > maxv) maxv = logits[v];
    }
    double sum = 0.0;
    for (int v = 0; v < n_vocab; v++) {
        sum += std::exp((double) logits[v] - (double) maxv);
    }
    return (double) logits[token] - (double) maxv - std::log(sum);
}

} // namespace

std::string llama_ctx_score_choices(uint64_t ctx, const char *choices,
                                    uint32_t choices_len) {
    CtxState *st = ctx_of(ctx);
    if (st == nullptr) return json_err("null context handle");
    try {
        const llama_vocab *vocab = llama_model_get_vocab(st->model);
        const int n_vocab = llama_vocab_n_tokens(vocab);

        // Split the newline-separated candidate list. An empty line is an
        // input error: it cannot be tokenized as a continuation.
        std::vector<std::string> items;
        {
            std::string all(choices, choices_len);
            size_t start = 0;
            while (start <= all.size()) {
                size_t nl = all.find('\n', start);
                if (nl == std::string::npos) nl = all.size();
                items.push_back(all.substr(start, nl - start));
                start = nl + 1;
            }
            while (!items.empty() && items.back().empty()) items.pop_back();
        }
        if (items.empty()) return json_err("score_choices: no choices");

        struct llama_memory_i *mem = llama_get_memory(st->ctx);
        const llama_pos base = llama_memory_seq_pos_max(mem, 0) + 1;
        if (base <= 0) return json_err("score_choices: nothing decoded yet");

        // The base logits (the position predicting each choice's first
        // token) cannot be read from the live buffer: any decode since the
        // stem — including a previous score_choices call's own choice
        // decodes — has clobbered it. Regenerate them deterministically by
        // re-decoding the stem's last token in place (remove position
        // base-1, decode the same token there again). The prefix history
        // knows that token; without valid history the stem's tail is
        // unknowable and the call is refused.
        if (!st->hist_valid || st->hist.empty()) {
            return json_err("score_choices: no prefix history "
                            "(decode the stem with eval or generate first)");
        }
        const llama_token last_tok = st->hist.back();
        llama_memory_seq_rm(mem, 0, base - 1, -1);
        {
            llama_batch batch = llama_batch_init(1, 0, 1);
            batch.token[0]     = last_tok;
            batch.pos[0]       = base - 1;
            batch.n_seq_id[0]  = 1;
            batch.seq_id[0][0] = 0;
            batch.logits[0]    = 1;
            batch.n_tokens     = 1;
            const int rc = llama_decode(st->ctx, batch);
            llama_batch_free(batch);
            if (rc != 0) {
                // Position base-1 was removed and its re-decode failed: the
                // cache no longer matches the prefix history. Invalidate the
                // history so the next call refuses instead of silently
                // re-anchoring the stem one position short.
                st->hist_valid = false;
                return json_err("score_choices: stem re-decode failed "
                                "(cache state discarded; re-decode the stem)");
            }
        }
        const float *live = llama_get_logits_ith(st->ctx, -1);
        if (live == nullptr) {
            st->hist_valid = false;
            return json_err("score_choices: no logits after stem re-decode "
                            "(cache state discarded; re-decode the stem)");
        }
        std::vector<float> base_logits(live, live + n_vocab);

        // Tokenize every choice up front; single-token choices are fully
        // scored by the base logits and never decode.
        const int n_batch_max = (int) llama_n_batch(st->ctx);
        std::vector<std::vector<llama_token>> toks(items.size());
        std::vector<double> nll(items.size());
        for (size_t c = 0; c < items.size(); c++) {
            std::string err;
            if (!tokenize_text(vocab, items[c], false, true, toks[c], err)) {
                return json_err("score_choices: " + err);
            }
            if (toks[c].empty()) return json_err("score_choices: empty choice");
            if (base + (llama_pos) toks[c].size() > (llama_pos) llama_n_ctx(st->ctx)) {
                return json_err("score_choices: choice exceeds the context window");
            }
            // A single decode carries at most n_batch tokens, and one choice
            // never splits across decodes; refuse up front with a precise
            // error instead of a generic decode failure below.
            if ((int) toks[c].size() - 1 > n_batch_max) {
                return json_err("score_choices: choice needs " +
                                json_num((double) (toks[c].size() - 1)) +
                                " decode tokens but n_batch is " +
                                json_num((double) n_batch_max));
            }
            nll[c] = -log_softmax_at(base_logits.data(), n_vocab, toks[c][0]);
        }

        // Teacher-force the multi-token choices. With n_seq_max > 1 the
        // choices batch into ONE decode per group: each choice runs on its
        // own sequence sharing the stem's cells (llama_memory_seq_cp on the
        // unified cache is metadata, not a copy), so the per-decode fixed
        // cost — the dominant cost of scoring many short candidates — is paid
        // once instead of once per choice. With n_seq_max == 1 (the context
        // default) each choice decodes on sequence 0 and rolls back, as many
        // decodes as choices.
        const uint32_t n_seq_max = llama_n_seq_max(st->ctx);
        const int      n_batch   = (int) llama_n_batch(st->ctx);
        std::vector<size_t> multi;
        for (size_t c = 0; c < items.size(); c++) {
            if (toks[c].size() > 1) multi.push_back(c);
        }
        size_t next = 0;
        while (next < multi.size()) {
            // One group: as many choices as spare sequences and batch room
            // allow (always at least one, so an oversized single choice
            // still decodes alone on sequence 0's in-place path below).
            std::vector<size_t> group;
            int tok_total = 0;
            const size_t max_group = n_seq_max > 1 ? (size_t) (n_seq_max - 1) : 1;
            while (next < multi.size() && group.size() < max_group) {
                const int need = (int) toks[multi[next]].size() - 1;
                if (!group.empty() && tok_total + need > n_batch) break;
                group.push_back(multi[next]);
                tok_total += need;
                next++;
            }
            const bool seq_batched = n_seq_max > 1 && group.size() >= 1;
            if (seq_batched) {
                for (size_t g = 0; g < group.size(); g++) {
                    llama_memory_seq_cp(mem, 0, (llama_seq_id) (g + 1), 0, -1);
                }
            }
            llama_batch batch = llama_batch_init(std::max(tok_total, 1), 0, 1);
            int row = 0;
            for (size_t g = 0; g < group.size(); g++) {
                const std::vector<llama_token> &t = toks[group[g]];
                const llama_seq_id sid = seq_batched ? (llama_seq_id) (g + 1) : 0;
                for (int i = 0; i + 1 < (int) t.size(); i++) {
                    batch.token[row]     = t[i];
                    batch.pos[row]       = base + i;
                    batch.n_seq_id[row]  = 1;
                    batch.seq_id[row][0] = sid;
                    batch.logits[row]    = 1;
                    row++;
                }
            }
            batch.n_tokens = row;
            const int rc = llama_decode(st->ctx, batch);
            llama_batch_free(batch);
            const auto cleanup = [&]() {
                if (seq_batched) {
                    for (size_t g = 0; g < group.size(); g++) {
                        llama_memory_seq_rm(mem, (llama_seq_id) (g + 1), -1, -1);
                    }
                } else {
                    llama_memory_seq_rm(mem, 0, base, -1);
                }
            };
            if (rc != 0) {
                cleanup();
                return json_err("score_choices: decode failed");
            }
            row = 0;
            for (size_t g = 0; g < group.size(); g++) {
                const std::vector<llama_token> &t = toks[group[g]];
                for (int i = 0; i + 1 < (int) t.size(); i++) {
                    const float *lg = llama_get_logits_ith(st->ctx, row);
                    if (lg == nullptr) {
                        cleanup();
                        return json_err("score_choices: no logits");
                    }
                    nll[group[g]] -= log_softmax_at(lg, n_vocab, t[i + 1]);
                    row++;
                }
            }
            cleanup();
        }

        std::string out = "{\"ok\":true,\"scores\":[";
        for (size_t c = 0; c < items.size(); c++) {
            if (c != 0) out.push_back(',');
            out += "{\"n_tokens\":" + json_num((double) toks[c].size()) +
                   ",\"nll\":" + json_num(nll[c]) + "}";
        }
        out += "]}";
        return out;
    } catch (const std::exception &e) {
        return json_err(std::string("score_choices: ") + e.what());
    } catch (...) {
        return json_err("score_choices: unknown error");
    }
}

/* ------------------------------------------------------------- embeddings */

namespace {

// embed_of decodes toks fresh (the KV cache is cleared first — an
// embedding is a function of the input alone) and renders the
// context's embedding as the JSON response both embed entry points
// share.
std::string embed_of(CtxState *st, std::vector<llama_token> &toks,
                     int32_t normalize) {
    if (toks.empty()) return json_err("embed: no tokens");

    // Scratch use of the cache, same as score.
    st->hist.clear();
    st->hist_valid = false;

    llama_memory_clear(llama_get_memory(st->ctx), true);
    llama_batch batch = llama_batch_get_one(toks.data(), (int32_t) toks.size());
    if (llama_decode(st->ctx, batch) != 0) return json_err("embed: decode failed");

    const int n_embd = llama_model_n_embd(st->model);
    const float *emb = llama_get_embeddings_seq(st->ctx, 0);
    if (emb == nullptr) emb = llama_get_embeddings(st->ctx);
    if (emb == nullptr) {
        return json_err("embed: no embeddings (create the context with embeddings=1)");
    }

    std::vector<float> v(emb, emb + n_embd);
    if (normalize != 0) {
        double sum = 0.0;
        for (float x : v) sum += (double) x * (double) x;
        const double norm = std::sqrt(sum);
        if (norm > 0.0) {
            for (float &x : v) x = (float) ((double) x / norm);
        }
    }
    std::string out = "{\"ok\":true,\"n_embd\":" + json_num(n_embd) + ",\"embedding\":[";
    for (size_t i = 0; i < v.size(); i++) {
        if (i != 0) out.push_back(',');
        out += json_num(v[i]);
    }
    out += "]}";
    return out;
}

} // namespace

std::string llama_ctx_embed(uint64_t ctx, const char *text, uint32_t text_len,
                            int32_t normalize) {
    CtxState *st = ctx_of(ctx);
    if (st == nullptr) return json_err("null context handle");
    try {
        const llama_vocab *vocab = llama_model_get_vocab(st->model);
        std::vector<llama_token> toks;
        std::string err;
        if (!tokenize_text(vocab, std::string(text, text_len), true, true, toks, err)) {
            return json_err(err);
        }
        if (toks.empty()) return json_err("embed: empty text");
        return embed_of(st, toks, normalize);
    } catch (const std::exception &e) {
        return json_err(std::string("embed: ") + e.what());
    } catch (...) {
        return json_err("embed: unknown error");
    }
}

std::string llama_ctx_embed_tokens(uint64_t ctx, const char *tokens_json,
                                   uint32_t tokens_json_len, int32_t normalize) {
    CtxState *st = ctx_of(ctx);
    if (st == nullptr) return json_err("null context handle");
    try {
        JsonReader r(tokens_json, tokens_json_len);
        if (!r.eat('[')) return json_err("embed_tokens: expected a JSON array");
        std::vector<llama_token> toks;
        if (!r.eat(']')) {
            for (;;) {
                double v = 0;
                if (!r.num(v)) return json_err("embed_tokens: bad token value");
                toks.push_back((llama_token) v);
                if (r.eat(',')) continue;
                if (!r.eat(']')) return json_err("embed_tokens: unterminated array");
                break;
            }
        }
        return embed_of(st, toks, normalize);
    } catch (const std::exception &e) {
        return json_err(std::string("embed_tokens: ") + e.what());
    } catch (...) {
        return json_err("embed_tokens: unknown error");
    }
}

/* ------------------------------------------------------------- kv / state */

std::string llama_ctx_eval(uint64_t ctx, const char *text, uint32_t text_len,
                           int32_t add_special, int32_t parse_special) {
    CtxState *st = ctx_of(ctx);
    if (st == nullptr) return json_err("null context handle");
    try {
        const llama_vocab *vocab = llama_model_get_vocab(st->model);
        std::vector<llama_token> toks;
        std::string err;
        if (!tokenize_text(vocab, std::string(text, text_len), add_special != 0,
                           parse_special != 0, toks, err)) {
            return json_err(err);
        }
        if (toks.empty()) return json_err("eval: empty text");
        const int n = (int) toks.size();

        // Same chunked decode as generation's prompt phase — splitting
        // at n_batch is the caller's job in llama.cpp — except the KV
        // cache is NOT cleared: positions continue where the cache
        // ends, which is what makes this usable as prompt prefill.
        const int nb = (int) llama_n_batch(st->ctx);
        for (int off = 0; off < n; off += nb) {
            const int take = std::min(nb, n - off);
            if (llama_decode(st->ctx, llama_batch_get_one(toks.data() + off, take)) != 0) {
                return json_err("eval: decode failed");
            }
            if (st->hist_valid) {
                st->hist.insert(st->hist.end(), toks.begin() + off,
                                toks.begin() + off + take);
            }
        }
        const llama_pos past = llama_memory_seq_pos_max(llama_get_memory(st->ctx), 0);
        return "{\"ok\":true,\"n_tokens\":" + json_num((double) n) +
               ",\"n_past\":" + json_num((double) (past + 1)) + "}";
    } catch (const std::exception &e) {
        return json_err(std::string("eval: ") + e.what());
    } catch (...) {
        return json_err("eval: unknown error");
    }
}

void llama_ctx_reset(uint64_t ctx) {
    CtxState *st = ctx_of(ctx);
    if (st == nullptr || st->ctx == nullptr) return;
    llama_memory_clear(llama_get_memory(st->ctx), true);
    st->hist.clear();
    st->hist_valid = true;
}

// The state blob is the engine's serialized state wrapped in a small bridge
// envelope that carries the prefix-history tokens alongside it, so a restored
// context composes with cache_prompt instead of forcing a full rebuild:
//
//   magic "LWSTATE1" | uint32 n_hist | n_hist * int32 tokens | llama state
//
// n_hist = 0xFFFFFFFF records "history was invalid at save time" (an empty
// but VALID history is a legitimate n_hist of 0). A blob without the magic is
// read as a bare llama state — what older bridges produced — and restores
// with the history invalid, exactly the old behavior. All fields are
// little-endian; the blob only ever lives in wasm memory, which is LE.
constexpr char kStateMagic[8] = {'L','W','S','T','A','T','E','1'};
constexpr uint32_t kHistInvalid = 0xFFFFFFFFu;

std::string llama_ctx_state_save(uint64_t ctx) {
    CtxState *st = ctx_of(ctx);
    if (st == nullptr) return json_err("null context handle");
    try {
        const size_t n = llama_state_get_size(st->ctx);
        const uint32_t n_hist =
            st->hist_valid ? (uint32_t) st->hist.size() : kHistInvalid;
        const size_t hist_bytes =
            st->hist_valid ? st->hist.size() * sizeof(int32_t) : 0;
        const size_t header = sizeof(kStateMagic) + sizeof(uint32_t);
        st->state_buf.resize(header + hist_bytes + n);
        uint8_t *p = st->state_buf.data();
        std::memcpy(p, kStateMagic, sizeof(kStateMagic));
        p += sizeof(kStateMagic);
        std::memcpy(p, &n_hist, sizeof(n_hist));
        p += sizeof(n_hist);
        if (hist_bytes != 0) {
            std::memcpy(p, st->hist.data(), hist_bytes);
            p += hist_bytes;
        }
        const size_t got = llama_state_get_data(st->ctx, p, n);
        if (got == 0 && n != 0) return json_err("state_save: failed");
        st->state_buf.resize(header + hist_bytes + got);
        return "{\"ok\":true,\"addr\":" +
               json_num((double) (uintptr_t) st->state_buf.data()) +
               ",\"size\":" + json_num((double) st->state_buf.size()) + "}";
    } catch (const std::exception &e) {
        return json_err(std::string("state_save: ") + e.what());
    } catch (...) {
        return json_err("state_save: unknown error");
    }
}

std::string llama_ctx_state_load(uint64_t ctx, const char *data,
                                 uint32_t size) {
    CtxState *st = ctx_of(ctx);
    if (st == nullptr) return json_err("null context handle");
    try {
        const uint8_t *src = reinterpret_cast<const uint8_t *>(data);
        size_t payload_off = 0;
        uint32_t n_hist = kHistInvalid;
        const size_t header = sizeof(kStateMagic) + sizeof(uint32_t);
        if (size >= header &&
            std::memcmp(src, kStateMagic, sizeof(kStateMagic)) == 0) {
            std::memcpy(&n_hist, src + sizeof(kStateMagic), sizeof(n_hist));
            payload_off = header;
            if (n_hist != kHistInvalid) {
                const size_t hist_bytes = (size_t) n_hist * sizeof(int32_t);
                if (header + hist_bytes > size) {
                    return json_err("state_load: truncated history");
                }
                payload_off += hist_bytes;
            }
        }
        const size_t used = llama_state_set_data(st->ctx, src + payload_off,
                                                 size - payload_off);
        if (used == 0 && size - payload_off != 0) {
            return json_err("state_load: rejected");
        }
        // Restore the prefix history saved with the state, so cache_prompt
        // picks up right where the snapshot left off. A bare or
        // invalid-history blob leaves it invalid: the next cache_prompt
        // generate rebuilds from scratch.
        st->hist.clear();
        st->hist_valid = false;
        if (payload_off != 0 && n_hist != kHistInvalid) {
            const int32_t *toks = reinterpret_cast<const int32_t *>(
                src + sizeof(kStateMagic) + sizeof(uint32_t));
            st->hist.assign(toks, toks + n_hist);
            st->hist_valid = true;
        }
        return "{\"ok\":true,\"used\":" + json_num((double) used) + "}";
    } catch (const std::exception &e) {
        return json_err(std::string("state_load: ") + e.what());
    } catch (...) {
        return json_err("state_load: unknown error");
    }
}

/* ------------------------------------------------------------------ error */

std::string llama_wasm_last_error() { return std::string(g_last_error); }
