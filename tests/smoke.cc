// Smoke test for the llama-wasm bridge: exercises every entry point the way
// the generated Go binding will, and prints the JSON so the shapes can be
// eyeballed against llama_api.h.
#include "llama_api.h"

#include <cinttypes>
#include <cstdio>
#include <cstring>
#include <string>
#include <vector>

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

// json_field_b64 returns the decoded bytes of the "b64" field of a result, or
// an empty string with ok=false when the field is missing. It is the test's
// own decoder so a bug in the bridge's encoder cannot hide behind itself.
static bool json_field_b64(const std::string &js, std::string &out) {
    const std::string key = "\"b64\":\"";
    const size_t at = js.find(key);
    if (at == std::string::npos) return false;
    const size_t end = js.find('"', at + key.size());
    if (end == std::string::npos) return false;
    const std::string enc = js.substr(at + key.size(), end - at - key.size());
    out.clear();
    uint32_t acc = 0;
    int bits = 0;
    for (char ch : enc) {
        int v;
        if (ch >= 'A' && ch <= 'Z') v = ch - 'A';
        else if (ch >= 'a' && ch <= 'z') v = ch - 'a' + 26;
        else if (ch >= '0' && ch <= '9') v = ch - '0' + 52;
        else if (ch == '+') v = 62;
        else if (ch == '/') v = 63;
        else if (ch == '=') break;
        else return false;
        acc = (acc << 6) | (uint32_t) v;
        bits += 6;
        if (bits >= 8) {
            bits -= 8;
            out.push_back((char) ((acc >> bits) & 0xff));
        }
    }
    return true;
}

// json_field_int returns the integer "key" field of a flat result.
static bool json_field_int(const std::string &js, const char *key, int &out) {
    const std::string k = std::string("\"") + key + "\":";
    const size_t at = js.find(k);
    if (at == std::string::npos) return false;
    out = atoi(js.c_str() + at + k.size());
    return true;
}

// json_events splits the "events" array of a slots_update result into its
// objects (top-level braces, string-aware) — the test's own scanner, so a
// bug in the bridge's writer cannot hide behind itself.
static std::vector<std::string> json_events(const std::string &js) {
    std::vector<std::string> out;
    const size_t at = js.find("\"events\":[");
    if (at == std::string::npos) return out;
    int depth = 0;
    bool instr = false;
    size_t start = 0;
    for (size_t i = at + 10; i < js.size(); i++) {
        const char c = js[i];
        if (instr) {
            if (c == '\\') i++;
            else if (c == '"') instr = false;
            continue;
        }
        if (c == '"') instr = true;
        else if (c == '{') { if (depth++ == 0) start = i; }
        else if (c == '}') { if (--depth == 0) out.push_back(js.substr(start, i - start + 1)); }
        else if (c == ']' && depth == 0) break;
    }
    return out;
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
    printf("progress_addr: %" PRIu64 "\n", llama_model_load_progress_addr());

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
    {
        std::string raw, escaped;
        check(json_field_b64(dt, raw), "detokenize carries b64");
        json_escape_into(escaped, raw);
        check(dt.find("\"text\":\"" + escaped + "\"") != std::string::npos, "detokenize b64 decodes to the text field");
    }

    // A byte-fallback token is a single byte >= 0x80: not valid UTF-8 on its
    // own, so a JSON string cannot carry it losslessly. Find one and make
    // sure the b64 fields of token_to_piece and detokenize both return
    // exactly that byte.
    {
        int32_t byte_tok = -1;
        std::string byte_piece;
        for (int32_t t = 0; t < 512 && byte_tok < 0; t++) {
            std::string raw;
            const std::string p = llama_token_to_piece(model, t, 0);
            if (json_ok(p) && json_field_b64(p, raw) && raw.size() == 1 && ((unsigned char) raw[0]) >= 0x80) {
                byte_tok = t;
                byte_piece = raw;
            }
        }
        check(byte_tok >= 0, "vocabulary has a byte-fallback token");
        if (byte_tok >= 0) {
            char one[16];
            snprintf(one, sizeof(one), "[%d]", byte_tok);
            std::string raw;
            const std::string d1 = llama_detokenize(model, one, (uint32_t) strlen(one), 0);
            check(json_ok(d1) && json_field_b64(d1, raw) && raw == byte_piece,
                  "detokenize returns a partial UTF-8 byte losslessly via b64");
        }
    }

    const std::string piece = llama_token_to_piece(model, 1, 0);
    check(json_ok(piece), "token_to_piece");

    const char *cparams = "{\"n_ctx\":128,\"n_threads\":1}";
    uint64_t ctx = llama_ctx_new(model, cparams, (uint32_t) strlen(cparams));
    check(ctx != 0, "ctx_new");
    if (ctx == 0) {
        printf("last_error: %s\n", llama_wasm_last_error().c_str());
        return 1;
    }
    printf("interrupt_addr: %" PRIu64 "\n", llama_ctx_interrupt_addr(ctx));

    const char *params = "{\"n_predict\":16,\"temperature\":0}";
    const std::string gen = llama_ctx_generate(ctx, text, (uint32_t) strlen(text),
                                               params, (uint32_t) strlen(params), nullptr);
    check(json_ok(gen), "generate");
    printf("generate: %s\n", gen.c_str());

    // Deterministic sampling must reproduce exactly.
    llama_ctx_reset(ctx);
    const std::string gen2 = llama_ctx_generate(ctx, text, (uint32_t) strlen(text),
                                                params, (uint32_t) strlen(params), nullptr);
    // Everything but the wall-clock timings must match.
    check(gen.substr(0, gen.find(",\"timings\"")) == gen2.substr(0, gen2.find(",\"timings\"")),
          "greedy generation is reproducible");

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
    {
        std::string raw;
        check(json_field_b64(gs, raw) && raw == sink.text, "generate b64 is byte-identical to the sink text");
        check(json_field_b64(gen, raw), "generate carries b64");
    }
    printf("sink: %d pieces: %s\n", sink.calls, sink.text.c_str());

    // Slots (continuous batching), with per-sequence KV streams and with a
    // shared buffer. Three tasks posted to a four-slot context must produce,
    // greedily, exactly what generating each of them alone produces, and the
    // partial texts must concatenate to the final text.
    for (int unified = 0; unified < 2; unified++) {
        const char *sctx_params = unified
            ? "{\"n_ctx\":256,\"n_threads\":1,\"n_seq_max\":4,\"kv_unified\":1}"
            : "{\"n_ctx\":1024,\"n_threads\":1,\"n_seq_max\":4}";
        uint64_t sctx = llama_ctx_new(model, sctx_params, (uint32_t) strlen(sctx_params));
        check(sctx != 0, "ctx_new with n_seq_max");
        printf("slots: kv_unified=%d\n", unified);
        const char *prompts[3] = {"Once upon a time", "The little girl", "One day"};
        std::string alone[3];
        for (int i = 0; i < 3; i++) {
            llama_ctx_reset(sctx);
            const std::string g = llama_ctx_generate(sctx, prompts[i], (uint32_t) strlen(prompts[i]),
                                                     params, (uint32_t) strlen(params), nullptr);
            check(json_ok(g), "slots: generate alone");
            check(json_field_b64(g, alone[i]), "slots: generate alone carries b64");
        }
        llama_ctx_reset(sctx);
        int ids[3] = {0, 0, 0};
        for (int i = 0; i < 3; i++) {
            const std::string task = std::string("{\"prompt\":\"") + prompts[i] + "\",\"n_predict\":16,\"temperature\":0}";
            const std::string r = llama_ctx_slots_post(sctx, task.c_str(), (uint32_t) task.size());
            check(json_ok(r) && json_field_int(r, "id", ids[i]) && ids[i] == i + 1, "slots_post");
        }
        check(!json_ok(llama_ctx_generate(sctx, text, (uint32_t) strlen(text), params, (uint32_t) strlen(params), nullptr)),
              "generate refuses while slots hold tasks");
        std::string finals[3], partials[3];
        bool done[3] = {false, false, false};
        int rounds = 0;
        while (!(done[0] && done[1] && done[2]) && rounds < 64) {
            const std::string u = llama_ctx_slots_update(sctx);
            check(json_ok(u), "slots_update");
            rounds++;
            for (const std::string &ev : json_events(u)) {
                int id = 0;
                check(json_field_int(ev, "id", id) && id >= 1 && id <= 3, "slots event carries a task id");
                if (id < 1 || id > 3) continue;
                std::string raw;
                check(json_field_b64(ev, raw), "slots event carries b64");
                if (ev.find("\"final\":") != std::string::npos) {
                    finals[id - 1] = raw;
                    done[id - 1] = true;
                } else if (ev.find("\"error\":") != std::string::npos) {
                    printf("slots error: %s\n", ev.c_str());
                    check(false, "slots task error");
                    done[id - 1] = true;
                } else {
                    partials[id - 1] += raw;
                }
            }
        }
        printf("slots: %d updates for 3 tasks\n", rounds);
        for (int i = 0; i < 3; i++) {
            check(done[i], "slots: every task finished");
            check(finals[i] == alone[i], "slots: batched task text equals the task generated alone");
            check(partials[i] == finals[i], "slots: partial texts concatenate to the final text");
        }
        check(json_ok(llama_ctx_generate(sctx, text, (uint32_t) strlen(text), params, (uint32_t) strlen(params), nullptr)),
              "generate runs again once the slots are idle");

        // System prompt: tasks whose prompt starts with it reuse its cells
        // and must still produce the text generated alone from the full
        // prompt, reporting the reuse in n_cached.
        {
            llama_ctx_reset(sctx);
            const char *sys = "Once upon a time";
            const std::string sp = llama_ctx_slots_system_prompt(sctx, sys, (uint32_t) strlen(sys));
            int n_sys = 0;
            check(json_ok(sp) && json_field_int(sp, "n_tokens", n_sys) && n_sys > 1, "slots_system_prompt");
            const char *tails[2] = {" there was", ", in a"};
            std::string alone2[2];
            for (int i = 0; i < 2; i++) {
                const std::string full = std::string(sys) + tails[i];
                const std::string g = llama_ctx_generate(sctx, full.c_str(), (uint32_t) full.size(), params, (uint32_t) strlen(params), nullptr);
                check(json_ok(g) && json_field_b64(g, alone2[i]), "system prompt: generate alone");
            }
            int sid[2] = {0, 0};
            for (int i = 0; i < 2; i++) {
                const std::string full = std::string(sys) + tails[i];
                const std::string task = "{\"prompt\":" + std::string("\"") + full + "\",\"n_predict\":16,\"temperature\":0}";
                const std::string r = llama_ctx_slots_post(sctx, task.c_str(), (uint32_t) task.size());
                check(json_ok(r) && json_field_int(r, "id", sid[i]), "system prompt: post");
            }
            std::string got2[2];
            int cached[2] = {0, 0};
            bool done2[2] = {false, false};
            for (int r = 0; r < 64 && !(done2[0] && done2[1]); r++) {
                const std::string u = llama_ctx_slots_update(sctx);
                check(json_ok(u), "system prompt: update");
                for (const std::string &ev : json_events(u)) {
                    int id = 0;
                    if (!json_field_int(ev, "id", id) || ev.find("\"final\":") == std::string::npos) continue;
                    const int k = id == sid[0] ? 0 : id == sid[1] ? 1 : -1;
                    if (k < 0) { check(false, "system prompt: unexpected task id"); continue; }
                    json_field_b64(ev, got2[k]);
                    json_field_int(ev, "n_cached", cached[k]);
                    done2[k] = true;
                }
            }
            for (int i = 0; i < 2; i++) {
                check(done2[i], "system prompt: task finished");
                check(got2[i] == alone2[i], "system prompt: reused prefix reproduces the text generated alone");
                check(cached[i] == n_sys - 1 || cached[i] == n_sys, "system prompt: n_cached reports the reuse");
            }
            const std::string ss = llama_ctx_slots_status(sctx);
            check(ss.find("\"n_slots\":3") != std::string::npos, "system prompt occupies one sequence");
            check(json_ok(llama_ctx_slots_system_prompt(sctx, "", 0)), "system prompt cleared");
            check(llama_ctx_slots_status(sctx).find("\"n_slots\":4") != std::string::npos, "system prompt sequence released");
        }

        // Cancel: a queued task disappears; a busy one returns its final.
        llama_ctx_reset(sctx);
        const char *ltask = "{\"prompt\":\"Once upon a time\",\"n_predict\":64,\"temperature\":0}";
        int ida = 0, idb = 0;
        check(json_field_int(llama_ctx_slots_post(sctx, ltask, (uint32_t) strlen(ltask)), "id", ida), "slots_post (cancel a)");
        check(json_field_int(llama_ctx_slots_post(sctx, ltask, (uint32_t) strlen(ltask)), "id", idb), "slots_post (cancel b)");
        const std::string cb = llama_ctx_slots_cancel(sctx, idb);
        check(json_ok(cb) && cb.find("\"queued\":true") != std::string::npos, "cancel of a queued task");
        check(json_ok(llama_ctx_slots_update(sctx)), "slots_update before cancel");
        check(json_ok(llama_ctx_slots_update(sctx)), "slots_update before cancel (2)");
        const std::string ca = llama_ctx_slots_cancel(sctx, ida);
        check(json_ok(ca) && ca.find("\"stop_reason\":\"interrupted\"") != std::string::npos, "cancel of a busy task returns its final");
        check(!json_ok(llama_ctx_slots_cancel(sctx, ida)), "cancel of an unknown task is an error");
        const std::string ss = llama_ctx_slots_status(sctx);
        check(json_ok(ss) && ss.find("\"active\":0") != std::string::npos && ss.find("\"queued\":0") != std::string::npos, "slots_status idle after cancel");
        printf("slots status: %s\n", ss.c_str());
        llama_ctx_free(sctx);
    }

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
