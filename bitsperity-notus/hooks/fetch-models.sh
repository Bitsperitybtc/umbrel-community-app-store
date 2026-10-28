#!/bin/sh
# Fetch the relation GGUFs into $MODEL_DIR (default /models). Idempotent: a file whose
# SHA256 already matches is kept; anything else is downloaded to .part, checked, then moved.
# Pinned HF revisions, no token. Runs in the llama.cpp server image (curl + sha256sum).
#
# d1:    LiquidAI/d1-2B-GGUF, the Q4_K_M from the eval bench.
# embed: ggml-org/embeddinggemma-2-GGUF Q8_0, converted from google/embeddinggemma-2, the
#        eval model m/eg2 (model.safetensors sha256 197a3296...3d79 at f9972ac2).
set -eu
dir="${MODEL_DIR:-/models}"
mkdir -p "$dir"
# Leftovers from an interrupted download (curl failed, container killed) are never reused.
rm -f "$dir"/*.part

fetch() { # repo revision file sha256
  dest="$dir/$3"
  if [ -f "$dest" ] && echo "$4  $dest" | sha256sum -c --status; then
    echo "ok $3"
    return 0
  fi
  echo "fetch $1@$2 $3"
  if ! curl -fsSL --retry 3 -o "$dest.part" "https://huggingface.co/$1/resolve/$2/$3"; then
    rm -f "$dest.part"
    echo "download failed $3" >&2
    return 1
  fi
  if ! echo "$4  $dest.part" | sha256sum -c --status; then
    rm -f "$dest.part"
    echo "sha256 mismatch $3" >&2
    return 1
  fi
  mv "$dest.part" "$dest"
  echo "ok $3"
}

fetch LiquidAI/d1-2B-GGUF 63be75e6586882defeb706ed4bda812d90256a6d \
  d1-2B-Q4_K_M.gguf adca5789ad30ae6027e8e936749bb9f19673097492ab26fa1c5b69643ca50b4b
fetch ggml-org/embeddinggemma-2-GGUF 58faf90940886df2d62be555c8765d00dac362c5 \
  embeddinggemma-2-Q8_0.gguf 2188ac1deca4b77dffefd603c2776a9d76d9d74ec01841392982ebb840b09135
