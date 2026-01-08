# Getting Started with Ollama

This guide walks you through your first steps with the Ollama Elixir client.

## Prerequisites

1. **Install Ollama**

   Download Ollama from https://ollama.com/download.

2. **Start Ollama Server**

   ```bash
   ollama serve
   ```

3. **Pull a Model**

   ```bash
   ollama pull llama3.2
   ```

   Browse models at https://ollama.com/search.

   For examples, also pull:

   ```bash
   ollama pull nomic-embed-text
   ollama pull llava
   ollama pull deepseek-r1:1.5b
   ```

## Add to Your Project

```elixir
# mix.exs
def deps do
  [{:ollama, "~> 0.10.0"}]
end
```

## Your First Chat

```elixir
# Start iex -S mix
iex> client = Ollama.init()
iex> {:ok, response} = Ollama.chat(client,
...>   model: "llama3.2",
...>   messages: [%{role: "user", content: "Hello!"}]
...> )
iex> response["message"]["content"]
"Hello! How can I help you today?"
```

## Understanding Responses

Chat responses include:

| Field | Description |
|-------|-------------|
| `message` | The assistant's response |
| `done` | Whether generation is complete |
| `model` | Model used |
| `total_duration` | Total time in nanoseconds |
| `eval_count` | Tokens generated |

## Typed Responses (Optional)

If you prefer response structs instead of maps:

```elixir
{:ok, response} = Ollama.chat(client,
  model: "llama3.2",
  messages: [%{role: "user", content: "Hello!"}],
  response_format: :struct
)

IO.puts(response.message.content)
```

## Next Steps

- [Streaming Guide](streaming.md) - Real-time responses
- [Tool Use Guide](tools.md) - Function calling
- [Thinking Mode](thinking.md) - Reasoning and chain-of-thought
- [Embeddings](embeddings.md) - Semantic search and RAG
- [Multimodal](multimodal.md) - Vision and image analysis
- [Cloud API](cloud-api.md) - Web search and cloud models
- [Ollama Server Setup](ollama-setup.md) - Local and cloud configuration
- [Examples](../examples/README.md) - Working code samples
