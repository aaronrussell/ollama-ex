# Ollama Elixir Examples

Examples demonstrating ollama-ex library features.

## Running Examples

```bash
# Most examples can be run directly with elixir
elixir examples/basic/chat.exs

# Some examples require a running Ollama server
ollama serve
```

## Example Categories

### Basic Operations
- [chat.exs](basic/chat.exs) - Simple chat request
- [completion.exs](basic/completion.exs) - Text completion
- [list_models.exs](basic/list_models.exs) - List available models
- [show_model.exs](basic/show_model.exs) - Model information

### Streaming
- [chat_stream.exs](streaming/chat_stream.exs) - Stream to enumerable
- [chat_stream_pid.exs](streaming/chat_stream_pid.exs) - Stream to process
- [liveview_chat.ex](streaming/liveview_chat.ex) - Phoenix LiveView integration

### Conversations
- [chat_history.exs](conversations/chat_history.exs) - Multi-turn chat
- [context_continuation.exs](conversations/context_continuation.exs) - Context preservation
- [system_prompts.exs](conversations/system_prompts.exs) - Custom system prompts

### Tools / Function Calling
- [basic_tools.exs](tools/basic_tools.exs) - Simple tool use
- [multi_tool.exs](tools/multi_tool.exs) - Multiple tools
- [tool_loop.exs](tools/tool_loop.exs) - Agentic tool loop

### Structured Output
- [json_format.exs](structured/json_format.exs) - JSON output
- [json_schema.exs](structured/json_schema.exs) - Schema enforcement
- [with_ecto.exs](structured/with_ecto.exs) - Ecto validation

### Multimodal
- [image_chat.exs](multimodal/image_chat.exs) - Image understanding
- [image_completion.exs](multimodal/image_completion.exs) - Image prompts

### Thinking Mode
- [basic_thinking.exs](thinking/basic_thinking.exs) - Enable thinking
- [thinking_stream.exs](thinking/thinking_stream.exs) - Stream thinking

### Embeddings
- [single_embed.exs](embeddings/single_embed.exs) - Single embedding
- [batch_embed.exs](embeddings/batch_embed.exs) - Batch embeddings
- [similarity.exs](embeddings/similarity.exs) - Cosine similarity

### Model Management
- [pull_progress.exs](model_management/pull_progress.exs) - Download with progress
- [create_custom.exs](model_management/create_custom.exs) - Custom models
- [preload_unload.exs](model_management/preload_unload.exs) - Memory management

### Advanced Patterns
- [concurrent_requests.exs](advanced/concurrent_requests.exs) - Parallel requests
- [rate_limiting.exs](advanced/rate_limiting.exs) - Request throttling
- [error_handling.exs](advanced/error_handling.exs) - Error patterns
- [genserver_integration.exs](advanced/genserver_integration.exs) - GenServer wrapper

## Requirements

- Elixir 1.15+
- Ollama installed and running (`ollama serve`)
- Models pulled (`ollama pull llama3.2`)
