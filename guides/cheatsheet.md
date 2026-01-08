# Ollama Elixir Cheatsheet

## Installation

```elixir
{:ollama, "~> 0.10.0"}
```

## Client

```elixir
client = Ollama.init()                              # Default
client = Ollama.init("http://host:11434")          # Custom host
client = Ollama.init("host:11434")                 # Host without scheme
client = Ollama.init(":11434")                     # Port-only host
client = Ollama.init(host: "host:11434")           # Host option
client = Ollama.init(receive_timeout: 120_000)     # With options
```

## Environment

```bash
export OLLAMA_HOST="http://host:11434"
export OLLAMA_API_KEY="your_api_key_here"
```

`OLLAMA_API_KEY` is required for web search/fetch and cloud tests.

## Chat

```elixir
Ollama.chat(client, model: "llama3.2", messages: [%{role: "user", content: "Hi"}])
```

## Completion

```elixir
Ollama.completion(client, model: "llama3.2", prompt: "Once upon a time")
```

## Streaming

```elixir
# Enumerable
{:ok, stream} = Ollama.chat(client, ..., stream: true)
Enum.each(stream, &IO.inspect/1)

# Process
{:ok, task} = Ollama.chat(client, ..., stream: self())
```

## Structured Output

```elixir
Ollama.chat(client, ..., format: %{type: "object", properties: %{...}})
```

## Tools

```elixir
Ollama.chat(client, ..., tools: [%{type: "function", function: %{name: "...", ...}}])
Ollama.chat(client, ..., tools: [&MyTools.add/2])       # Function → tool
Ollama.Tool.define(:get_weather, description: "...", parameters: [...])
```

## Images (Multimodal)

```elixir
Ollama.chat(client, ..., messages: [%{role: "user", content: "Describe", images: ["./photo.jpg"]}])
Ollama.completion(client, ..., images: ["./photo.jpg"])
```

## Options

```elixir
opts = Ollama.Options.Presets.creative() |> Ollama.Options.temperature(0.9)
Ollama.chat(client, ..., options: opts)
```

## Typed Responses

```elixir
Ollama.chat(client, ..., response_format: :struct)
```

## Web (Cloud API)

```elixir
Ollama.web_search(client, query: "elixir language")
Ollama.web_fetch(client, url: "https://elixir-lang.org")
```

## Thinking

```elixir
Ollama.chat(client, ..., think: true)
```

## Embeddings

```elixir
Ollama.embed(client, model: "nomic-embed-text", input: "text")
Ollama.embed(client, model: "nomic-embed-text", input: ["text1", "text2"])
```

## Model Management

```elixir
Ollama.list_models(client)                          # List all
Ollama.list_running(client)                         # Running models
Ollama.show_model(client, name: "llama3.2")        # Model info
Ollama.pull_model(client, name: "llama3.2")        # Download
Ollama.preload(client, model: "llama3.2")          # Load to memory
Ollama.unload(client, model: "llama3.2")           # Unload
Ollama.copy_model(client, source: "a", destination: "b")
Ollama.delete_model(client, name: "model")
```

## Response Fields

| Chat | Completion |
|------|------------|
| `response["message"]["content"]` | `response["response"]` |
| `response["message"]["thinking"]` | `response["thinking"]` |
| `response["message"]["tool_calls"]` | N/A |

## Common Options

| Option | Description |
|--------|-------------|
| `:model` | Model name |
| `:stream` | `true` or `pid` |
| `:format` | `"json"` or schema |
| `:response_format` | `:map` (default) or `:struct` |
| `:think` | Enable thinking (`true` or `"low"|"medium"|"high"`) |
| `:logprobs` | Return token log probabilities |
| `:top_logprobs` | Alternatives per token (0-20) |
| `:suffix` | FIM suffix (completion only) |
| `:dimensions` | Embedding output size (embed only) |
| `:keep_alive` | Memory duration |
| `:options` | Model params |
