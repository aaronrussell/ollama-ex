# Ollama

![Ollama-ex](https://raw.githubusercontent.com/lebrunel/ollama-ex/main/media/poster.png)

[![Hex.pm](https://img.shields.io/hexpm/v/ollama?color=informational)](https://hex.pm/packages/ollama)
[![License](https://img.shields.io/github/license/lebrunel/ollama-ex?color=informational)](https://github.com/lebrunel/ollama-ex/blob/main/LICENSE)
[![Build Status](https://img.shields.io/github/actions/workflow/status/lebrunel/ollama-ex/elixir.yml?branch=main)](https://github.com/lebrunel/ollama-ex/actions)

[Ollama](https://ollama.com) runs large language models locally or on your infrastructure.
This library provides a first-class Elixir client with feature parity to the official
ollama-python library.

## Features

- Chat, generate, embeddings, and full model management API coverage
- Streaming to an `Enumerable` or directly to any process
- Tool use (function calling) + function-to-tool helpers
- Structured outputs (JSON or JSON Schema)
- Multimodal image support with automatic Base64 encoding
- Typed responses (`response_format: :struct`) and typed options (`Ollama.Options`)
- Cloud API: web search and web fetch

## Prerequisites

1. Install Ollama: https://ollama.com/download
2. Start the server (if needed): `ollama serve`
3. Pull a model: `ollama pull llama3.2`

For examples, also pull:

- `ollama pull nomic-embed-text` (embeddings)
- `ollama pull llava` (multimodal)
- `ollama pull deepseek-r1:1.5b` (thinking)

Thinking examples use `deepseek-r1:1.5b`, which supports `think`.

For full setup details (including cloud usage and Linux manual install), see
[Ollama Server Setup](guides/ollama-setup.md).

## Installation

Requires Elixir 1.15+.

```elixir
def deps do
  [
    {:ollama, "~> 0.10.0"}
  ]
end
```

## Quickstart

### 1. Chat

```elixir
client = Ollama.init()

{:ok, response} = Ollama.chat(client,
  model: "llama3.2",
  messages: [%{role: "user", content: "Why is the sky blue?"}]
)

IO.puts(response["message"]["content"])
```

### 2. Completion

```elixir
{:ok, response} = Ollama.completion(client,
  model: "llama3.2",
  prompt: "The capital of France is"
)

IO.puts(response["response"])
```

### 3. Structured output

```elixir
schema = %{
  type: "object",
  properties: %{
    name: %{type: "string"},
    capital: %{type: "string"},
    languages: %{type: "array", items: %{type: "string"}}
  },
  required: ["name", "capital", "languages"]
}

{:ok, response} = Ollama.chat(client,
  model: "llama3.2",
  messages: [%{role: "user", content: "Tell me about Canada."}],
  format: schema
)

{:ok, data} = Jason.decode(response["message"]["content"])
IO.inspect(data)
```

## Typed responses

Return response structs instead of maps by setting `response_format: :struct`:

```elixir
{:ok, response} = Ollama.chat(client,
  model: "llama3.2",
  messages: [%{role: "user", content: "Summarize Elixir."}],
  response_format: :struct
)

IO.puts(response.message.content)
```

You can also set a default:

```elixir
Application.put_env(:ollama, :response_format, :struct)
```

## Streaming

### Enumerable mode

```elixir
{:ok, stream} = Ollama.chat(client,
  model: "llama3.2",
  messages: [%{role: "user", content: "Tell me a short story."}],
  stream: true
)

stream
|> Stream.each(fn chunk ->
  if content = get_in(chunk, ["message", "content"]) do
    IO.write(content)
  end
end)
|> Stream.run()
```

### Process mode

```elixir
{:ok, task} = Ollama.chat(client,
  model: "llama3.2",
  messages: [%{role: "user", content: "Stream to my process"}],
  stream: self()
)

receive do
  {_pid, {:data, chunk}} -> IO.inspect(chunk)
end

Task.await(task, 60_000)
```

## Multimodal images

You can pass image paths, binary data, or pre-encoded Base64. The client will
encode automatically:

```elixir
image_path = "/path/to/photo.jpg"

{:ok, response} = Ollama.chat(client,
  model: "llava",
  messages: [%{role: "user", content: "Describe this image.", images: [image_path]}]
)

IO.puts(response["message"]["content"])
```

Use `Ollama.Image.encode/1` to pre-encode images if you prefer.

## Tools (function calling)

Define tools manually or use helpers:

```elixir
calculator = Ollama.Tool.define(:calculator,
  description: "Evaluate a math expression",
  parameters: [expression: [type: :string, required: true]]
)

{:ok, response} = Ollama.chat(client,
  model: "llama3.2",
  messages: [%{role: "user", content: "What is 9 * 9?"}],
  tools: [calculator]
)
```

You can also pass functions directly and let Ollama convert them to tools:

```elixir
defmodule MathTools do
  @doc "Add two integers together."
  @spec add(integer(), integer()) :: integer()
  def add(a, b), do: a + b
end

{:ok, response} = Ollama.chat(client,
  model: "llama3.2",
  messages: [%{role: "user", content: "Add 4 and 7"}],
  tools: [&MathTools.add/2]
)
```

## Options

Use the `Ollama.Options` struct or presets:

```elixir
opts =
  Ollama.Options.Presets.creative()
  |> Ollama.Options.temperature(0.9)
  |> Ollama.Options.top_p(0.95)

{:ok, response} = Ollama.chat(client,
  model: "llama3.2",
  messages: [%{role: "user", content: "Write a playful haiku."}],
  options: opts
)
```

## Embeddings

```elixir
{:ok, response} = Ollama.embed(client,
  model: "nomic-embed-text",
  input: ["The sky is blue", "The grass is green"]
)

IO.inspect(response["embeddings"])
```

## Web search and fetch (cloud API)

These calls require an Ollama API key (`OLLAMA_API_KEY`):

```elixir
{:ok, results} = Ollama.web_search(client, query: "Elixir language")
{:ok, page} = Ollama.web_fetch(client, url: "https://elixir-lang.org")
```

### Cloud API key setup

1) Create an Ollama account: https://ollama.com
2) Generate a key: https://ollama.com/settings/keys
3) Export it:

```bash
export OLLAMA_API_KEY="your_api_key_here"
```

If the key is missing, web examples will skip with a helpful message. If the
key is invalid, you will see a 401/403 response from the API.

When passing headers explicitly, the `authorization` value must start with
`Bearer `.

## Cloud Models and Hosted API

### Use cloud models via local Ollama

1) Sign in (one-time):

```bash
ollama signin
```

2) Pull a cloud model:

```bash
ollama pull gpt-oss:120b-cloud
```

3) Make a request:

```elixir
{:ok, stream} = Ollama.chat(client,
  model: "gpt-oss:120b-cloud",
  messages: [%{role: "user", content: "Why is the sky blue?"}],
  stream: true
)

Stream.each(stream, fn chunk ->
  IO.write(get_in(chunk, ["message", "content"]) || "")
end)
|> Stream.run()
```

Supported cloud model names currently include:

- `deepseek-v3.1:671b-cloud`
- `gpt-oss:20b-cloud`
- `gpt-oss:120b-cloud`
- `kimi-k2:1t-cloud`
- `qwen3-coder:480b-cloud`
- `kimi-k2-thinking`

See https://ollama.com/search?c=cloud for updates.

### Call the hosted API (ollama.com)

1) Create an API key: https://ollama.com/settings/keys

2) Export the key:

```bash
export OLLAMA_API_KEY="your_api_key_here"
```

3) (Optional) List models:

```bash
curl https://ollama.com/api/tags
```

4) Point the client at the hosted API:

```elixir
client = Ollama.init("https://ollama.com")

{:ok, response} = Ollama.chat(client,
  model: "gpt-oss:120b",
  messages: [%{role: "user", content: "Why is the sky blue?"}]
)
```

`OLLAMA_API_KEY` is used automatically if it is set. To override headers:

```elixir
client = Ollama.init("https://ollama.com",
  headers: [{"authorization", "Bearer your_api_key_here"}]
)
```

## Client configuration

```elixir
client = Ollama.init("http://localhost:11434")
client = Ollama.init("localhost:11434")
client = Ollama.init(":11434")
client = Ollama.init(host: "ollama.internal:11434")
client = Ollama.init(headers: [{"x-some-header", "some-value"}])
client = Ollama.init(receive_timeout: 120_000)

req = Req.new(base_url: "http://localhost:11434/api", headers: [{"x-env", "dev"}])
client = Ollama.init(req)
```

Environment variables:

- `OLLAMA_HOST` sets the default host (e.g. `http://localhost:11434`)
- `OLLAMA_API_KEY` provides a bearer token for the hosted API

## Error handling

All functions return `{:ok, result}` or `{:error, reason}`:

```elixir
case Ollama.chat(client, model: "not-found", messages: [%{role: "user", content: "Hi"}]) do
  {:ok, response} -> response
  {:error, %Ollama.RequestError{} = error} -> IO.puts("Request error: #{Exception.message(error)}")
  {:error, %Ollama.ResponseError{} = error} -> IO.puts("Response error: #{Exception.message(error)}")
end
```

## API surface

The client mirrors the Ollama REST API, with Python-style aliases where helpful:

```elixir
Ollama.chat(client, model: "llama3.2", messages: [%{role: "user", content: "Hello"}])
Ollama.completion(client, model: "llama3.2", prompt: "Hello")
Ollama.generate(client, model: "llama3.2", prompt: "Hello")
Ollama.list_models(client)
Ollama.list(client)
Ollama.show_model(client, name: "llama3.2")
Ollama.show(client, name: "llama3.2")
Ollama.list_running(client)
Ollama.ps(client)
Ollama.create_model(client, name: "example", from: "llama3.2", system: "You are Mario.")
Ollama.create(client, name: "example", from: "llama3.2")
Ollama.copy_model(client, source: "llama3.2", destination: "user/llama3.2")
Ollama.copy(client, source: "llama3.2", destination: "user/llama3.2")
Ollama.delete_model(client, name: "llama3.2")
Ollama.delete(client, name: "llama3.2")
Ollama.pull_model(client, name: "llama3.2")
Ollama.pull(client, name: "llama3.2")
Ollama.push_model(client, name: "user/llama3.2")
Ollama.push(client, name: "user/llama3.2")
Ollama.embed(client, model: "nomic-embed-text", input: "The sky is blue.")
Ollama.embeddings(client, model: "llama3.2", prompt: "Legacy embeddings")
Ollama.web_search(client, query: "Elixir language")
Ollama.web_fetch(client, url: "https://elixir-lang.org")
```

## Examples and Guides

- [Examples](examples/README.md)
- [Getting Started](guides/getting-started.md)
- [Streaming](guides/streaming.md)
- [Tools](guides/tools.md)
- [Structured Outputs](guides/structured-outputs.md)
- [Thinking Mode](guides/thinking.md)
- [Embeddings](guides/embeddings.md)
- [Multimodal](guides/multimodal.md)
- [Cloud API](guides/cloud-api.md)
- [Ollama Server Setup](guides/ollama-setup.md)
- [Cheatsheet](guides/cheatsheet.md)

## License

This package is open source and released under the [Apache-2 License](https://github.com/lebrunel/ollama/blob/master/LICENSE).

© Copyright 2024-2026 [Push Code Ltd](https://www.pushcode.com/).
