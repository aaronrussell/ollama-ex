#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

MODELS=(
  "llama3.2"
  "nomic-embed-text"
  "llava"
  "deepseek-r1:1.5b"
  "codellama:7b-code"
)

if [[ -n "${OLLAMA_MODELS:-}" ]]; then
  read -r -a MODELS <<<"${OLLAMA_MODELS}"
fi

if ! command -v ollama >/dev/null 2>&1; then
  echo "ollama CLI not found; skipping model install." >&2
  exit 0
fi

if ! ollama_models=$(ollama list 2>/dev/null | awk 'NR>1 {print $1}'); then
  echo "ollama list failed; skipping model install." >&2
  exit 0
fi

has_model() {
  local model="$1"

  if [[ "$model" == *:* ]]; then
    echo "$ollama_models" | awk -v m="$model" '$1==m { found=1 } END { exit !found }'
  else
    echo "$ollama_models" | awk -v m="$model" '$1==m || $1==m":latest" { found=1 } END { exit !found }'
  fi
}

ensure_model() {
  local model="$1"

  if ! has_model "$model"; then
    echo "[ollama] Pulling ${model}..."
    if ollama pull "$model"; then
      ollama_models=$(ollama list 2>/dev/null | awk 'NR>1 {print $1}' || true)
    else
      echo "[ollama] Failed to pull ${model}; continuing." >&2
    fi
  fi
}

for model in "${MODELS[@]}"; do
  ensure_model "$model"
done
