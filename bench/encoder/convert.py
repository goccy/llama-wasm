"""Convert a ModernBERT checkpoint whose tokenizer is a SentencePiece unigram
model (sbintuitions/modernbert-ja-*) to GGUF with the submodule's converter.

Usage: convert.py <llama.cpp dir> <hf model dir> <out.gguf> [f32|f16|q8_0]

llama.cpp's ModernBERT converter writes a WordPiece vocabulary; these
checkpoints carry unigram pieces, so the vocab is written the way the T5
converter does (tokenizer model "t5", llama.cpp's UGM tokenizer)."""
import os
import sys

llama_dir, hf_dir, out = sys.argv[1], sys.argv[2], sys.argv[3]
ftype = sys.argv[4] if len(sys.argv) > 4 else "f32"
sys.path.insert(0, llama_dir)
sys.path.insert(0, os.path.join(llama_dir, "gguf-py"))
os.environ.setdefault("PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION", "python")

import gguf  # noqa: E402
from conversion import ModelBase  # noqa: E402
from conversion.bert import ModernBertModel  # noqa: E402
from conversion.t5 import T5Model  # noqa: E402


@ModelBase.register("ModernBertModel", "ModernBertForMaskedLM")
class ModernBertUnigramModel(ModernBertModel):
    model_arch = gguf.MODEL_ARCH.MODERN_BERT

    # The masked-LM head (head.*, decoder.*) has no place in the encoder
    # graph; drop it so a *ForMaskedLM checkpoint converts like the bare
    # encoder.
    @classmethod
    def filter_tensors(cls, item):
        name = item[0]
        if name.startswith(("head.", "decoder.")):
            return None
        return super().filter_tensors(item)

    def set_vocab(self):
        T5Model.set_vocab(self)
        self.gguf_writer.add_add_bos_token(True)
        self.gguf_writer.add_add_eos_token(True)


sys.argv = ["convert_hf_to_gguf.py", "--outtype", ftype, "--outfile", out, hf_dir]
import convert_hf_to_gguf  # noqa: E402

convert_hf_to_gguf.main()
