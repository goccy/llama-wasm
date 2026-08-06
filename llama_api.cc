/* llama_api.cc — implementation of the thin llama.cpp embedding API.
 *
 * Everything llama.cpp can throw is caught at this boundary: an exception
 * must never cross into the generated Go, so each entry point that can fail
 * either returns a JSON object carrying "ok"/"error" or returns the null
 * handle and records the message for llama_wasm_last_error.
 */

#include "llama_api.h"

#include "llama.h"

#include <algorithm>
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

uint32_t llama_model_load_progress_addr() {
    return (uint32_t) (uintptr_t) &g_load_progress;
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
        if (c == nullptr) {
            set_error("failed to create context");
            return 0;
        }
        auto *st = new CtxState();
        st->ctx   = c;
        st->model = ms->model;
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
    delete st;
}

uint32_t llama_ctx_interrupt_addr(uint64_t ctx) {
    CtxState *st = ctx_of(ctx);
    if (st == nullptr) return 0;
    return (uint32_t) (uintptr_t) &st->interrupt;
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

        // Decode the prompt in n_batch-sized chunks: llama_decode rejects
        // a batch larger than the context's n_batch, and splitting is the
        // CALLER's job (native llama.cpp CLIs do the same). The interrupt
        // flag is honoured between chunks so a long prompt can be stopped.
        const int nb = (int) llama_n_batch(st->ctx);
        int n_decoded = 0;
        bool prompt_ok = true;
        for (int off = 0; off < n_prompt && !interrupted; off += nb) {
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
        }
        if (!prompt_ok) {
            st->generating = false;
            llama_sampler_free(smpl);
            return json_err("generate: decode failed");
        }
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
        out += ",\"n_decoded\":" + json_num(n_decoded);
        out += ",\"stop_reason\":" + json_str(stop_reason);
        out += ",\"interrupted\":" + std::string(interrupted ? "true" : "false");
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

        llama_memory_clear(llama_get_memory(st->ctx), true);
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

/* ------------------------------------------------------------- embeddings */

namespace {

// embed_of decodes toks fresh (the KV cache is cleared first — an
// embedding is a function of the input alone) and renders the
// context's embedding as the JSON response both embed entry points
// share.
std::string embed_of(CtxState *st, std::vector<llama_token> &toks,
                     int32_t normalize) {
    if (toks.empty()) return json_err("embed: no tokens");

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
}

std::string llama_ctx_state_save(uint64_t ctx) {
    CtxState *st = ctx_of(ctx);
    if (st == nullptr) return json_err("null context handle");
    try {
        const size_t n = llama_state_get_size(st->ctx);
        st->state_buf.resize(n);
        const size_t got = llama_state_get_data(st->ctx, st->state_buf.data(), n);
        if (got == 0 && n != 0) return json_err("state_save: failed");
        return "{\"ok\":true,\"addr\":" +
               json_num((double) (uintptr_t) st->state_buf.data()) +
               ",\"size\":" + json_num((double) got) + "}";
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
        const size_t used = llama_state_set_data(st->ctx, src, size);
        if (used == 0 && size != 0) return json_err("state_load: rejected");
        return "{\"ok\":true,\"used\":" + json_num((double) used) + "}";
    } catch (const std::exception &e) {
        return json_err(std::string("state_load: ") + e.what());
    } catch (...) {
        return json_err("state_load: unknown error");
    }
}

/* ------------------------------------------------------------------ error */

std::string llama_wasm_last_error() { return std::string(g_last_error); }
