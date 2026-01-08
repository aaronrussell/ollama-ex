# Ollama

![Ollama-ex](https://raw.githubusercontent.com/lebrunel/ollama-ex/main/media/poster.webp)

[![Hex.pm](https://img.shields.io/hexpm/v/ollama?color=informational)](https://hex.pm/packages/ollama)
[![License](https://img.shields.io/github/license/lebrunel/ollama-ex?color=informational)](https://github.com/lebrunel/ollama-ex/blob/main/LICENSE)
[![Build Status](https://img.shields.io/github/actions/workflow/status/lebrunel/ollama-ex/elixir.yml?branch=main)](https://github.com/lebrunel/ollama-ex/actions)

[Ollama](https://ollama.com) is a powerful tool for running large language models locally or on your own infrastructure. This library provides an interface for working with Ollama in Elixir.

- 🦙 Full implementation of the Ollama API
- 🧠 Extended thinking
- 🧰 Tool use (function calling)
- 🧱 Structured outputs
- 🛜 Streaming requests
  - Stream to an Enumerable
  - Or stream messages to any Elixir process

## Prerequisites

1. **Install Ollama**
   - https://ollama.com/download
2. **Start the server (if it is not already running)**
   - `ollama serve`
3. **Pull a model**
   - `ollama pull llama3.2`
   - Browse models at https://ollama.com/search

For full setup details, including cloud usage, see
[Ollama Server Setup](guides/ollama-setup.md).

## Installation

Requires Elixir 1.15+.

The package can be installed by adding `ollama` to your list of dependencies in `mix.exs`.

```elixir
def deps do
  [
    {:ollama, "~> 0.10.0"}
  ]
end
```

## Quickstart

For more examples, refer to the [Ollama documentation](https://hexdocs.pm/ollama) or the
[`examples/`](examples/README.md) directory.

### 1. Generate a completion

```elixir
client = Ollama.init()

Ollama.completion(client, [
  model: "llama3.2",
  prompt: "Why is the sky blue?",
])
# {:ok, %{"response" => "The sky is blue because it is the color of the sky.", ...}}
```

### 2. Generate the next message in a chat

```elixir
Ollama.chat(client, [
  model: "llama3.2",
  messages: [
    %{role: "system", content: "You are a helpful assistant."},
    %{role: "user", content: "Why is the sky blue?"},
    %{role: "assistant", content: "Due to rayleigh scattering."},
    %{role: "user", content: "How is that different than mie scattering?"},
  ]
])
# {:ok, %{"message" => %{
#   "role" => "assistant",
#   "content" => "Mie scattering affects all wavelengths similarly, while Rayleigh favors shorter ones."
# }, ...}}
```

### 3. Generate structured data

The `:format` option can be used with both `completion/2` and `chat/2`.

```elixir
Ollama.completion(client, [
  model: "llama3.2",
  prompt: "Tell me about Canada",
  format: %{
    type: "object",
    properties: %{
      name: %{type: "string"},
      capital: %{type: "string"},
      languages: %{type: "array", items: %{type: "string"}},
    },
    required: ["name", "capital", "languages"]
  }
])
# {:ok, %{"response" => "{ \"name\": \"Canada\" ,\"capital\": \"Ottawa\" ,\"languages\": [\"English\", \"French\"] }", ...}}
```

## Client configuration

Create a client with a custom host or headers:

```elixir
client = Ollama.init("http://localhost:11434")
client = Ollama.init(headers: [{"x-some-header", "some-value"}])
client = Ollama.init(receive_timeout: 120_000)
```

You can also build a custom `Req.Request` and pass it through:

```elixir
req = Req.new(base_url: "http://localhost:11434/api", headers: [{"x-env", "dev"}])
client = Ollama.init(req)
```

Environment variables:

- `OLLAMA_HOST` sets the default host (e.g. `http://localhost:11434`)
- `OLLAMA_API_KEY` provides a bearer token for the hosted API

## Concurrent requests

Ollama calls are synchronous. Use tasks to run concurrent requests:

```elixir
prompts = [
  "Why is the sky blue?",
  "Explain gravity in one sentence."
]

responses =
  prompts
  |> Task.async_stream(fn prompt ->
    Ollama.chat(Ollama.init(),
      model: "llama3.2",
      messages: [%{role: "user", content: prompt}]
    )
  end,
    max_concurrency: 4,
    timeout: 60_000
  )
  |> Enum.to_list()
```

## Examples

Run all examples against a local Ollama server:

```bash
./examples/run_all.sh
```

See [`examples/README.md`](examples/README.md) for details and individual runs.

## Cloud Models and Hosted API

Ollama provides cloud models and a hosted API. You can run cloud models through
your local Ollama instance or call the hosted API directly.

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
client = Ollama.init()

{:ok, stream} = Ollama.chat(client, [
  model: "gpt-oss:120b-cloud",
  messages: [%{role: "user", content: "Why is the sky blue?"}],
  stream: true
])

stream
|> Stream.each(fn chunk ->
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

{:ok, response} = Ollama.chat(client, [
  model: "gpt-oss:120b",
  messages: [%{role: "user", content: "Why is the sky blue?"}]
])
```

The client will add the `Authorization` header automatically when
`OLLAMA_API_KEY` is set. To override headers explicitly:

```elixir
client = Ollama.init("https://ollama.com",
  headers: [{"authorization", "Bearer your_api_key_here"}]
)
```

## Streaming

Streaming is supported on certain endpoints by setting the `:stream` option to `true` or a `t:pid/0`.

When `:stream` is set to `true`, a lazy `t:Enumerable.t/0` is returned, which can be used with any `Stream` functions.

```elixir
{:ok, stream} = Ollama.completion(client, [
  model: "llama3.2",
  prompt: "Why is the sky blue?",
  stream: true,
])

stream
|> Stream.each(& Process.send(pid, &1, [])
|> Stream.run()
# :ok
```

This approach above builds the `t:Enumerable.t/0` by calling `receive`, which may cause issues in `GenServer` callbacks. As an alternative, you can set the `:stream` option to a `t:pid/0`. This returns a `t:Task.t/0` that sends messages to the specified process.

The following example demonstrates a streaming request in a LiveView event, sending each streaming message back to the same LiveView process:

```elixir
defmodule MyApp.ChatLive do
  use Phoenix.LiveView

  # When the client invokes the "prompt" event, create a streaming request and
  # asynchronously send messages back to self.
  def handle_event("prompt", %{"message" => prompt}, socket) do
    {:ok, task} = Ollama.completion(Ollama.init(), [
      model: "llama3.2",
      prompt: prompt,
      stream: self(),
    ])

    {:noreply, assign(socket, current_request: task)}
  end

  # The streaming request sends messages back to the LiveView process.
  def handle_info({_request_pid, {:data, _data}} = message, socket) do
    pid = socket.assigns.current_request.pid
    case message do
      {^pid, {:data, %{"done" => false} = data}} ->
        # handle each streaming chunk

      {^pid, {:data, %{"done" => true} = data}} ->
        # handle the final streaming chunk

      {_pid, _data} ->
        # this message was not expected!
    end
  end

  # Tidy up when the request is finished
  def handle_info({ref, {:ok, %Req.Response{status: 200}}}, socket) do
    Process.demonitor(ref, [:flush])
    {:noreply, assign(socket, current_request: nil)}
  end
end
```

Regardless of the streaming approach used, each streaming message is a plain `t:map/0`. For the message schema, refer to the [Ollama API docs](https://github.com/ollama/ollama/blob/main/docs/api.md).

## Function calling

Ollama 0.3 and later versions support tool use and function calling on compatible models.
Tool calling is model-dependent, so check the model card if you do not see `tool_calls` in responses.
Ollama currently doesn't support tool use with streaming requests, so avoid setting `:stream` to `true`.

Using tools typically involves at least two round-trip requests to the model. Begin by defining one or more tools using a schema similar to ChatGPT's. Provide clear and concise descriptions for the tool and each argument.

```elixir
stock_price_tool = %{
  type: "function",
  function: %{
    name: "get_stock_price",
    description: "Fetches the live stock price for the given ticker.",
    parameters: %{
      type: "object",
      properties: %{
        ticker: %{
          type: "string",
          description: "The ticker symbol of a specific stock."
        }
      },
      required: ["ticker"]
    }
  }
}
```

The first round-trip involves sending a prompt in a chat with the tool definitions. The model should respond with a message containing a list of tool calls.

```elixir
Ollama.chat(client, [
  model: "llama3.2",
  messages: [
    %{role: "user", content: "What is the current stock price for Apple?"}
  ],
  tools: [stock_price_tool],
])
# {:ok, %{"message" => %{
#   "role" => "assistant",
#   "content" => "",
#   "tool_calls" => [
#     %{"function" => %{
#       "name" => "get_stock_price",
#       "arguments" => %{"ticker" => "AAPL"}
#     }}
#   ]
# }, ...}}
```

Your implementation must intercept these tool calls and execute a corresponding function in your codebase with the specified arguments. The next round-trip involves passing the function's result back to the model as a message with a `:role` of `"tool"`.

```elixir
Ollama.chat(client, [
  model: "llama3.2",
  messages: [
    %{role: "user", content: "What is the current stock price for Apple?"},
    %{role: "assistant", content: "", tool_calls: [%{"function" => %{"name" => "get_stock_price", "arguments" => %{"ticker" => "AAPL"}}}]},
    %{role: "tool", content: "$217.96"},
  ],
  tools: [stock_price_tool],
])
# {:ok, %{"message" => %{
#   "role" => "assistant",
#   "content" => "The current stock price for Apple (AAPL) is approximately $217.96.",
# }, ...}}
```

After receiving the function tool's value, the model will respond to the user's original prompt, incorporating the function result into its response.

## API surface

The client mirrors the Ollama REST API:

```elixir
Ollama.chat(client, model: "llama3.2", messages: [%{role: "user", content: "Hello"}])
Ollama.completion(client, model: "llama3.2", prompt: "Hello")
Ollama.list_models(client)
Ollama.show_model(client, name: "llama3.2")
Ollama.create_model(client, name: "example", from: "llama3.2", system: "You are Mario.")
Ollama.copy_model(client, source: "llama3.2", destination: "user/llama3.2")
Ollama.delete_model(client, name: "llama3.2")
Ollama.pull_model(client, name: "llama3.2")
Ollama.push_model(client, name: "user/llama3.2")
Ollama.embed(client, model: "nomic-embed-text", input: "The sky is blue.")
```

## License

This package is open source and released under the [Apache-2 License](https://github.com/lebrunel/ollama/blob/master/LICENSE).

© Copyright 2024-2026 [Push Code Ltd](https://www.pushcode.com/).
