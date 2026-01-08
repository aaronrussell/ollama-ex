# Ollama Elixir Cheatsheet

## Installation

```elixir
{:ollama, "~> 0.9"}
```

## Client

```elixir
client = Ollama.init()                              # Default
client = Ollama.init("http://host:11434")          # Custom host
client = Ollama.init(receive_timeout: 120_000)     # With options
```

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
| `:think` | Enable thinking |
| `:keep_alive` | Memory duration |
| `:options` | Model params |
```
