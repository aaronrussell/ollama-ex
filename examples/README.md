# Ollama Elixir Examples

Examples demonstrating ollama-ex features, designed to run against a real Ollama server.

## Run everything

```bash
./examples/run_all.sh
```

The runner will:

- Verify the Ollama server is reachable (default: `http://localhost:11434`).
- Pull required models if the `ollama` CLI is available (`llama3.2`, `nomic-embed-text`, `llava`, `deepseek-r1:1.5b`).
- Run every example, including the interactive chat history and LiveView module compile.
- Skip cloud/web examples if `OLLAMA_API_KEY` is not set (invalid keys report 401/403).
- Multimodal examples require a compatible model (`llava`). If not installed, they print a prompt.
- Thinking examples use `deepseek-r1:1.5b` (supports `think`).
- Skip custom model creation unless `RUN_CREATE_MODEL=1` (it writes a new local model).

Run `./examples/run_all.sh --help` to see optional skips.

## Run a single example

```bash
elixir examples/basic/chat.exs
```

## Example map

### Basic operations
- [chat.exs](basic/chat.exs) - Simple chat request
- [completion.exs](basic/completion.exs) - Text completion
- [list_models.exs](basic/list_models.exs) - List available models
- [show_model.exs](basic/show_model.exs) - Model details

### Streaming
- [chat_stream.exs](streaming/chat_stream.exs) - Stream to enumerable
- [chat_stream_pid.exs](streaming/chat_stream_pid.exs) - Stream to process (PID)
- [completion_stream.exs](streaming/completion_stream.exs) - Stream completion output
- [liveview_chat.ex](streaming/liveview_chat.ex) - Phoenix LiveView module example (prints snippet if LiveView isn't available)

### Conversations
- [chat_history.exs](conversations/chat_history.exs) - Multi-turn chat (type `quit` to exit)
- [context_continuation.exs](conversations/context_continuation.exs) - Continue using context
- [system_prompts.exs](conversations/system_prompts.exs) - System role messages

### Tools / Function Calling
- [basic_tools.exs](tools/basic_tools.exs) - Simple tool use
- [multi_tool.exs](tools/multi_tool.exs) - Multiple tools
- [function_tools.exs](tools/function_tools.exs) - Function → tool conversion
- [tool_loop.exs](tools/tool_loop.exs) - Agentic tool loop

### Structured Output
- [json_format.exs](structured/json_format.exs) - `format: "json"`
- [json_schema.exs](structured/json_schema.exs) - Schema enforcement
- [with_ecto.exs](structured/with_ecto.exs) - Validate with Ecto changeset

### Multimodal
- [image_chat.exs](multimodal/image_chat.exs) - Image + chat
- [image_completion.exs](multimodal/image_completion.exs) - Image + completion

### Thinking Mode
- [basic_thinking.exs](thinking/basic_thinking.exs) - Enable thinking
- [thinking_stream.exs](thinking/thinking_stream.exs) - Stream thinking + response

### Embeddings
- [single_embed.exs](embeddings/single_embed.exs) - Single embedding
- [batch_embed.exs](embeddings/batch_embed.exs) - Batch embeddings
- [similarity.exs](embeddings/similarity.exs) - Cosine similarity

### Model Management
- [pull_progress.exs](model_management/pull_progress.exs) - Pull with progress
- [create_custom.exs](model_management/create_custom.exs) - Create a custom model
- [preload_unload.exs](model_management/preload_unload.exs) - Load/unload models

### Web (Cloud API)
- [web_search.exs](web/web_search.exs) - Web search (requires API key)
- [web_fetch.exs](web/web_fetch.exs) - Web fetch (requires API key)

### Advanced Patterns
- [concurrent_requests.exs](advanced/concurrent_requests.exs) - Task.async_stream
- [rate_limiting.exs](advanced/rate_limiting.exs) - Simple throttling
- [error_handling.exs](advanced/error_handling.exs) - Request/response errors
- [options_presets.exs](advanced/options_presets.exs) - Options presets
- [typed_responses.exs](advanced/typed_responses.exs) - Response structs
- [genserver_integration.exs](advanced/genserver_integration.exs) - GenServer wrapper

## Requirements

- Elixir 1.15+
- Ollama installed and running (`ollama serve`)
- Models pulled (`ollama pull llama3.2`, `ollama pull nomic-embed-text`, `ollama pull llava`, `ollama pull deepseek-r1:1.5b`)
- For web examples: create a key at https://ollama.com/settings/keys and set `OLLAMA_API_KEY`
