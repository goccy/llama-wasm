// Smoke test for the llama-wasm bridge: exercises every entry point the way
// the generated Go binding will, and prints the JSON so the shapes can be
// eyeballed against llama_api.h.
#include "llama_api.h"

#include <cstdio>
#include <cstring>
#include <string>

static int failures = 0;

static void check(bool cond, const char *what) {
    if (!cond) {
        printf("FAIL: %s\n", what);
        failures++;
    }
}

static bool json_ok(const std::string &s) {
    return s.find("\"ok\":true") != std::string::npos;
}

// json_escape_into applies the same escaping llama_api.cc's writer does, so a
// raw byte string can be searched for inside a returned JSON document. Only
// the escapes the writer can emit are covered; anything else passes through.
static void json_escape_into(std::string &out, const std::string &s) {
    char buf[8];
    for (unsigned char c : s) {
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
                    snprintf(buf, sizeof(buf), "\\u%04x", c);
                    out += buf;
                } else {
                    out.push_back((char) c);
                }
        }
    }
}

// CollectingSink is the in-process stand-in for the Go implementation the
// bridge generates: it just accumulates what the generation loop hands it.
struct CollectingSink : llama_wasm::token_sink {
    std::string text;
    int         calls = 0;
    void on_piece(const std::string &piece) override {
        text += piece;
        calls++;
    }
};

int main(int argc, char **argv) {
    const char *path = argc > 1 ? argv[1] : "stories260K.gguf";

    printf("build: %s\n", llama_wasm_build_info().c_str());

    uint64_t model = llama_model_load(path, (uint32_t) strlen(path), 0, 0);
    check(model != 0, "model_load");
    if (model == 0) {
        printf("last_error: %s\n", llama_wasm_last_error().c_str());
        return 1;
    }
    const std::string info = llama_model_info(model);
    check(json_ok(info), "model_info");
    printf("info: %s\n", info.c_str());
    printf("progress_addr: %u\n", llama_model_load_progress_addr());

    const char *text = "Once upon a time";
    const std::string tk = llama_tokenize(model, text, (uint32_t) strlen(text), 1, 1);
    check(json_ok(tk), "tokenize");
    printf("tokenize: %s\n", tk.c_str());

    // Round-trip the tokens the tokenizer just produced.
    const size_t lb = tk.find('[');
    const size_t rb = tk.find(']');
    check(lb != std::string::npos && rb != std::string::npos, "tokenize array");
    const std::string arr = tk.substr(lb, rb - lb + 1);
    const std::string dt = llama_detokenize(model, arr.data(), (uint32_t) arr.size(), 0);
    check(json_ok(dt), "detokenize");
    printf("detokenize: %s\n", dt.c_str());

    const std::string piece = llama_token_to_piece(model, 1, 0);
    check(json_ok(piece), "token_to_piece");

    uint64_t ctx = llama_ctx_new(model, 128, 0, 0, 1, 0, 0);
    check(ctx != 0, "ctx_new");
    if (ctx == 0) {
        printf("last_error: %s\n", llama_wasm_last_error().c_str());
        return 1;
    }
    printf("interrupt_addr: %u\n", llama_ctx_interrupt_addr(ctx));

    const char *params = "{\"n_predict\":16,\"temperature\":0}";
    const std::string gen = llama_ctx_generate(ctx, text, (uint32_t) strlen(text),
                                               params, (uint32_t) strlen(params), nullptr);
    check(json_ok(gen), "generate");
    printf("generate: %s\n", gen.c_str());

    // Deterministic sampling must reproduce exactly.
    llama_ctx_reset(ctx);
    const std::string gen2 = llama_ctx_generate(ctx, text, (uint32_t) strlen(text),
                                                params, (uint32_t) strlen(params), nullptr);
    check(gen == gen2, "greedy generation is reproducible");

    // Stop strings.
    const char *pstop = "{\"n_predict\":32,\"temperature\":0,\"stop\":[\" \"]}";
    llama_ctx_reset(ctx);
    const std::string gstop = llama_ctx_generate(ctx, text, (uint32_t) strlen(text),
                                                 pstop, (uint32_t) strlen(pstop), nullptr);
    check(json_ok(gstop), "generate with stop");
    check(gstop.find("\"stop_reason\":\"stop\"") != std::string::npos, "stop_reason=stop");
    printf("stop: %s\n", gstop.c_str());

    // The token sink must see exactly the text generation returned, one call
    // per decoded token.
    const char *pstream = "{\"n_predict\":8,\"temperature\":0}";
    llama_ctx_reset(ctx);
    CollectingSink sink;
    const std::string gs = llama_ctx_generate(ctx, text, (uint32_t) strlen(text),
                                              pstream, (uint32_t) strlen(pstream), &sink);
    check(json_ok(gs), "generate with a sink");
    check(sink.calls == 8, "one sink call per decoded token");
    check(!sink.text.empty(), "sink received text");
    // The returned JSON carries the same text, escaped; comparing against the
    // escaped form keeps this honest for pieces containing quotes or newlines.
    std::string escaped;
    json_escape_into(escaped, sink.text);
    check(gs.find(escaped) != std::string::npos, "sink text matches the returned text");
    printf("sink: %d pieces: %s\n", sink.calls, sink.text.c_str());

    // State save/load.
    const std::string save = llama_ctx_state_save(ctx);
    check(json_ok(save), "state_save");
    printf("state_save: %s\n", save.c_str());

    // Chat template: this tiny model has none, so the call must fail cleanly
    // unless an override is supplied.
    const char *msgs = "[{\"role\":\"user\",\"content\":\"hi\"}]";
    const std::string chat = llama_chat_apply_template(model, msgs, (uint32_t) strlen(msgs),
                                                       "", 0, 1);
    printf("chat(no template): %s\n", chat.c_str());
    const char *tmpl = "chatml";
    const std::string chat2 = llama_chat_apply_template(model, msgs, (uint32_t) strlen(msgs),
                                                        tmpl, (uint32_t) strlen(tmpl), 1);
    check(json_ok(chat2), "chat_apply_template with override");
    printf("chat(chatml): %s\n", chat2.c_str());

    // A bad handle must be reported, never crash.
    check(!json_ok(llama_model_info(0)), "null model handle rejected");
    check(!json_ok(llama_ctx_generate(0, text, 4, params, 4, nullptr)), "null ctx handle rejected");

    // A missing model file must fail gracefully (exercises the exception path).
    const char *bad = "/nonexistent.gguf";
    check(llama_model_load(bad, (uint32_t) strlen(bad), 0, 0) == 0, "missing model rejected");
    printf("last_error: %s\n", llama_wasm_last_error().c_str());

    llama_ctx_free(ctx);
    llama_model_free(model);
    llama_wasm_free();

    printf(failures == 0 ? "ALL OK\n" : "FAILURES: %d\n", failures);
    return failures == 0 ? 0 : 1;
}
