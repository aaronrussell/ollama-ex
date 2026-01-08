# Ollama Server Setup

This guide covers installing Ollama, running the local server, pulling models,
and connecting to local or cloud endpoints from the Elixir client.

## Install Ollama

Download and install Ollama for your platform:

- https://ollama.com/download

Verify the CLI is available:

```bash
ollama --version
```

## Start the Server

If you installed the desktop app, the server is often started for you. On
headless or CLI-only setups, start it manually:

```bash
ollama serve
```

The default base URL is `http://localhost:11434`.

## Pull a Model

Download a model before sending requests:

```bash
ollama pull llama3.2
```

Browse available models:

- https://ollama.com/search

You can confirm local models with:

```bash
ollama list
```

Or via the API:

```bash
curl http://localhost:11434/api/tags
```

## Connect from Elixir

By default, the client targets `http://localhost:11434`:

```elixir
client = Ollama.init()
```

To point at a different host or port, set `OLLAMA_HOST`:

```bash
export OLLAMA_HOST="http://ollama.internal:11434"
```

```elixir
client = Ollama.init()
```

You can also pass the URL directly (the client appends `/api` for you):

```elixir
client = Ollama.init("http://ollama.internal:11434")
```

## Cloud Models (via Local Ollama)

Cloud models let you run larger models while keeping the same local workflow.
Supported cloud model names currently include:

- `deepseek-v3.1:671b-cloud`
- `gpt-oss:20b-cloud`
- `gpt-oss:120b-cloud`
- `kimi-k2:1t-cloud`
- `qwen3-coder:480b-cloud`
- `kimi-k2-thinking`

See the latest list at:

- https://ollama.com/search?c=cloud

To use cloud models through your local Ollama instance:

1) Sign in (one time):

```bash
ollama signin
```

2) Pull a cloud model:

```bash
ollama pull gpt-oss:120b-cloud
```

3) Use it like any other model:

```elixir
client = Ollama.init()

{:ok, stream} = Ollama.chat(client,
  model: "gpt-oss:120b-cloud",
  messages: [%{role: "user", content: "Why is the sky blue?"}],
  stream: true
)

stream
|> Stream.each(fn chunk ->
  IO.write(get_in(chunk, ["message", "content"]) || "")
end)
|> Stream.run()
```

## Cloud API (ollama.com)

You can also call the hosted API directly.

1) Create an API key at:

- https://ollama.com/settings/keys

Then export it:

```bash
export OLLAMA_API_KEY="your_api_key_here"
```

2) (Optional) List available models:

```bash
curl https://ollama.com/api/tags
```

3) Point the client at the hosted API:

```elixir
client = Ollama.init("https://ollama.com")

{:ok, response} = Ollama.chat(client,
  model: "gpt-oss:120b",
  messages: [%{role: "user", content: "Why is the sky blue?"}]
)
```

`OLLAMA_API_KEY` is used automatically if it is set. If you need to override
headers explicitly:

```elixir
client = Ollama.init("https://ollama.com",
  headers: [{"authorization", "Bearer your_api_key_here"}]
)
```

## Troubleshooting

- `connection refused`: ensure `ollama serve` is running and reachable.
- Wrong host/port: set `OLLAMA_HOST` or pass a URL to `Ollama.init/1`.
- Auth errors: confirm your API key and target host.

## Next Steps

- [Getting Started](getting-started.md)
- [Streaming](streaming.md)
- [Tools](tools.md)
