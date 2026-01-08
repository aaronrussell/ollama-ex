# Ollama Elixir Examples

Examples demonstrating ollama-ex features, designed to run against a real Ollama server.

## Run everything

```bash
./examples/run_all.sh
```

The runner will:

- Verify the Ollama server is reachable (default: `http://localhost:11434`).
- Pull required models if the `ollama` CLI is available.
- Run every example, including the interactive chat history and LiveView module compile.

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

### Streaming
- [chat_stream.exs](streaming/chat_stream.exs) - Stream to enumerable
- [liveview_chat.ex](streaming/liveview_chat.ex) - Phoenix LiveView module example (prints snippet if LiveView isn't available)

### Conversations
- [chat_history.exs](conversations/chat_history.exs) - Multi-turn chat (type `quit` to exit)

### Tools / Function Calling
- [basic_tools.exs](tools/basic_tools.exs) - Simple tool use
- [tool_loop.exs](tools/tool_loop.exs) - Agentic tool loop

### Structured Output
- [json_schema.exs](structured/json_schema.exs) - Schema enforcement

### Thinking Mode
- [basic_thinking.exs](thinking/basic_thinking.exs) - Enable thinking

### Embeddings
- [similarity.exs](embeddings/similarity.exs) - Cosine similarity

### Advanced Patterns
- [genserver_integration.exs](advanced/genserver_integration.exs) - GenServer wrapper

## Requirements

- Elixir 1.15+
- Ollama installed and running (`ollama serve`)
- Models pulled (`ollama pull llama3.2`, `ollama pull nomic-embed-text`)
