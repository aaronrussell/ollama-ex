# Cloud API

Ollama provides cloud capabilities including web search, web fetch, cloud models,
and a hosted API. This guide covers all cloud features.

## API Key Setup

Cloud features require an Ollama API key:

1. Create an account at https://ollama.com
2. Generate a key at https://ollama.com/settings/keys
3. Export the key:

```bash
export OLLAMA_API_KEY="your_api_key_here"
```

The client automatically uses `OLLAMA_API_KEY` when set.

## Web Search

Search the web and get structured results:

```elixir
{:ok, response} = Ollama.web_search(client, query: "Elixir programming language")

for result <- response.results do
  IO.puts("#{result.title}")
  IO.puts("  #{result.url}")
  IO.puts("  #{result.content}")
end
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `query` | string | required | Search query |
| `max_results` | integer | 3 | Maximum results to return |

### Response Structure

```elixir
%Ollama.Web.SearchResponse{
  results: [
    %Ollama.Web.SearchResult{
      title: "Elixir Programming Language",
      url: "https://elixir-lang.org",
      content: "Elixir is a dynamic, functional language..."
    }
  ]
}
```

## Web Fetch

Fetch and extract content from a URL:

```elixir
{:ok, response} = Ollama.web_fetch(client, url: "https://elixir-lang.org")

IO.puts("Title: #{response.title}")
IO.puts("Content: #{response.content}")
IO.inspect(response.links, label: "Links")
```

### Response Structure

```elixir
%Ollama.Web.FetchResponse{
  title: "The Elixir programming language",
  content: "Elixir is a dynamic, functional language...",
  links: ["https://...", "https://..."]
}
```

## Web Tools for Agents

Use web capabilities as tools in agentic workflows.

See `examples/mcp/mcp_server.exs` for an MCP stdio server that exposes
web_search and web_fetch to MCP clients (Cursor, Cline, Open WebUI, etc.).

```elixir
# Get predefined web tool definitions
tools = Ollama.Web.Tools.all()

{:ok, response} = Ollama.chat(client,
  model: "llama3.2",
  messages: [
    %{role: "user", content: "Search for the latest Elixir news"}
  ],
  tools: tools
)

# Handle tool calls
case get_in(response, ["message", "tool_calls"]) do
  [%{"function" => %{"name" => "web_search", "arguments" => args}}] ->
    query = args["query"]
    {:ok, results} = Ollama.web_search(client, query: query)
    # Continue conversation with results...

  _ ->
    response["message"]["content"]
end
```

## Cloud Models

Cloud models run on Ollama's infrastructure while using your local client.

### Setup

1. Sign in (one-time):

```bash
ollama signin
```

2. Pull a cloud model:

```bash
ollama pull gpt-oss:120b-cloud
```

3. Use it like any local model:

```elixir
client = Ollama.init()

{:ok, response} = Ollama.chat(client,
  model: "gpt-oss:120b-cloud",
  messages: [%{role: "user", content: "Explain quantum computing."}]
)
```

### Available Cloud Models

| Model | Size | Features |
|-------|------|----------|
| `deepseek-v3.1:671b-cloud` | 671B | General purpose |
| `gpt-oss:20b-cloud` | 20B | Thinking levels |
| `gpt-oss:120b-cloud` | 120B | Thinking levels |
| `kimi-k2:1t-cloud` | 1T | Large scale |
| `kimi-k2-thinking` | - | Reasoning model |
| `qwen3-coder:480b-cloud` | 480B | Code generation |

See https://ollama.com/search?c=cloud for the latest list.

### Cloud Models with Streaming

```elixir
{:ok, stream} = Ollama.chat(client,
  model: "gpt-oss:120b-cloud",
  messages: [%{role: "user", content: "Write a haiku about Elixir."}],
  stream: true
)

stream
|> Stream.each(fn chunk ->
  IO.write(get_in(chunk, ["message", "content"]) || "")
end)
|> Stream.run()
```

## Hosted API (ollama.com)

Use the Ollama-hosted API directly instead of a local server:

```elixir
# Point client at hosted API
client = Ollama.init("https://ollama.com")

{:ok, response} = Ollama.chat(client,
  model: "gpt-oss:120b",  # Note: no :cloud suffix for hosted API
  messages: [%{role: "user", content: "Hello!"}]
)
```

### List Available Models

```bash
curl -H "Authorization: Bearer $OLLAMA_API_KEY" https://ollama.com/api/tags
```

### Custom Headers

Override the default authorization:

```elixir
client = Ollama.init("https://ollama.com",
  headers: [{"authorization", "Bearer your_api_key_here"}]
)
```

## Cloud vs Local Comparison

| Feature | Local Ollama | Cloud Models | Hosted API |
|---------|--------------|--------------|------------|
| Server | Your machine | Your machine | ollama.com |
| Models | Downloaded | Streamed | Remote |
| API Key | Optional | Required (signin) | Required |
| Latency | Lowest | Medium | Highest |
| Model Size | Limited by hardware | Very large | Very large |

## Error Handling

### Missing API Key

```elixir
case Ollama.web_search(client, query: "test") do
  {:ok, response} ->
    response

  {:error, %Ollama.ResponseError{status: 401}} ->
    IO.puts("Missing or invalid API key. Set OLLAMA_API_KEY.")

  {:error, %Ollama.ResponseError{status: 403}} ->
    IO.puts("API key lacks permission for this operation.")

  {:error, error} ->
    IO.puts("Request failed: #{inspect(error)}")
end
```

### Validate API Key

```bash
curl -H "Authorization: Bearer $OLLAMA_API_KEY" https://ollama.com/api/tags
```

## Rate Limiting

Cloud APIs may have rate limits. Implement backoff:

```elixir
defmodule CloudClient do
  def search_with_retry(client, query, retries \\ 3) do
    case Ollama.web_search(client, query: query) do
      {:ok, response} ->
        {:ok, response}

      {:error, %Ollama.ResponseError{status: 429}} when retries > 0 ->
        Process.sleep(1000 * (4 - retries))
        search_with_retry(client, query, retries - 1)

      {:error, error} ->
        {:error, error}
    end
  end
end
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `OLLAMA_HOST` | Default server URL |
| `OLLAMA_API_KEY` | Bearer token for cloud features |

## Testing Cloud Features

Cloud tests are tagged and excluded by default:

```bash
# Run cloud tests after setting API key
mix test --include cloud_api
```

## See Also

- [Getting Started](getting-started.md) - Basic setup
- [Tools Guide](tools.md) - Using web tools in agents
- [Ollama Server Setup](ollama-setup.md) - Local and cloud setup
