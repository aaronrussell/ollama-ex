#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<'USAGE'
Usage: examples/run_all.sh [options]

Options:
  --skip-interactive  Skip interactive examples (chat history)
  --skip-liveview     Skip LiveView example (prints snippet if LiveView isn't available)
  --skip-check        Skip Ollama server connectivity check
  --skip-pull         Skip model pull/check step
  -h, --help          Show this help

Environment:
  OLLAMA_HOST          Base URL for Ollama (default: http://localhost:11434)
  ELIXIR_BIN           Elixir executable (default: elixir)
USAGE
}

skip_interactive=false
skip_liveview=false
skip_check=false
skip_pull=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-interactive)
      skip_interactive=true
      shift
      ;;
    --skip-liveview)
      skip_liveview=true
      shift
      ;;
    --skip-check)
      skip_check=true
      shift
      ;;
    --skip-pull)
      skip_pull=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

OLLAMA_HOST="${OLLAMA_HOST:-http://localhost:11434}"
OLLAMA_HOST="${OLLAMA_HOST%/}"
if [[ "$OLLAMA_HOST" == */api ]]; then
  OLLAMA_HOST="${OLLAMA_HOST%/api}"
fi
export OLLAMA_HOST
ELIXIR_BIN="${ELIXIR_BIN:-elixir}"

if [[ "$skip_check" == "false" ]]; then
  if command -v curl >/dev/null 2>&1; then
    if ! curl -fsS "${OLLAMA_HOST}/api/tags" >/dev/null 2>&1; then
      echo "Ollama server not reachable at ${OLLAMA_HOST}." >&2
      echo "Start Ollama or set OLLAMA_HOST, or rerun with --skip-check." >&2
      exit 1
    fi
  else
    echo "curl not found; skipping Ollama connectivity check." >&2
  fi
fi

declare -a examples=(
  "basic/chat.exs"
  "basic/completion.exs"
  "basic/list_models.exs"
  "basic/show_model.exs"
  "streaming/chat_stream.exs"
  "streaming/chat_stream_pid.exs"
  "streaming/completion_stream.exs"
  "conversations/context_continuation.exs"
  "conversations/system_prompts.exs"
  "tools/basic_tools.exs"
  "tools/multi_tool.exs"
  "tools/function_tools.exs"
  "structured/json_schema.exs"
  "structured/json_format.exs"
  "structured/with_ecto.exs"
  "multimodal/image_chat.exs"
  "multimodal/image_completion.exs"
  "tools/tool_loop.exs"
  "thinking/basic_thinking.exs"
  "thinking/thinking_stream.exs"
  "embeddings/single_embed.exs"
  "embeddings/batch_embed.exs"
  "embeddings/similarity.exs"
  "model_management/pull_progress.exs"
  "model_management/create_custom.exs"
  "model_management/preload_unload.exs"
  "web/web_search.exs"
  "web/web_fetch.exs"
  "advanced/chat_logprobs.exs"
  "advanced/completion_logprobs.exs"
  "advanced/fill_in_middle.exs"
  "advanced/concurrent_requests.exs"
  "advanced/rate_limiting.exs"
  "advanced/error_handling.exs"
  "advanced/options_presets.exs"
  "advanced/typed_responses.exs"
  "advanced/genserver_integration.exs"
)

declare -a skipped=()

if [[ "$skip_interactive" == "true" ]]; then
  skipped+=("conversations/chat_history.exs")
fi

if [[ "$skip_liveview" == "true" ]]; then
  skipped+=("streaming/liveview_chat.ex")
fi

if [[ ${#skipped[@]} -gt 0 ]]; then
  echo "Skipping: ${skipped[*]}"
fi

cd "$ROOT_DIR"

if [[ "$skip_pull" == "false" ]]; then
  "$SCRIPT_DIR/install_models.sh"
fi

run_example() {
  local example="$1"
  echo ""
  echo "==> examples/${example}"
  "$ELIXIR_BIN" "$SCRIPT_DIR/$example"
}

run_example_with_input() {
  local example="$1"
  local input="$2"
  echo ""
  echo "==> examples/${example}"
  printf "%b" "$input" | "$ELIXIR_BIN" "$SCRIPT_DIR/$example"
}

for example in "${examples[@]}"; do
  run_example "$example"
done

if [[ "$skip_interactive" == "false" ]]; then
  run_example_with_input "conversations/chat_history.exs" "Hello!\nquit\n"
fi

if [[ "$skip_liveview" == "false" ]]; then
  run_example "streaming/liveview_chat.ex"
fi
