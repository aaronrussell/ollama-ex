# Thinking Mode

Thinking mode enables models to show their reasoning process before providing
a final answer. This is useful for complex problems where you want to see how
the model arrives at its conclusion.

## Overview

When thinking is enabled, the model response includes both:
- `thinking` - The model's internal reasoning process
- `content` - The final answer

## Enabling Thinking

```elixir
{:ok, response} = Ollama.chat(client,
  model: "deepseek-r1:1.5b",
  messages: [%{role: "user", content: "How many Rs are in 'strawberry'?"}],
  think: true
)

# Access thinking and response
IO.puts("Thinking: #{response["message"]["thinking"]}")
IO.puts("Answer: #{response["message"]["content"]}")
```

## Thinking Levels

Some models support different thinking intensities:

| Level | Description | Use Case |
|-------|-------------|----------|
| `true` | Default thinking | General reasoning |
| `"low"` | Light thinking | Simple problems |
| `"medium"` | Standard thinking | Moderate complexity |
| `"high"` | Deep reasoning | Complex problems |

```elixir
# Deep reasoning for complex problems
{:ok, response} = Ollama.chat(client,
  model: "gpt-oss:20b-cloud",
  messages: [%{role: "user", content: "Prove that sqrt(2) is irrational."}],
  think: "high"
)
```

## Compatible Models

| Model | Think Support | Levels |
|-------|---------------|--------|
| `deepseek-r1` | Yes | Boolean only |
| `deepseek-r1:1.5b` | Yes | Boolean only |
| `gpt-oss:20b-cloud` | Yes | low/medium/high |
| `gpt-oss:120b-cloud` | Yes | low/medium/high |
| `kimi-k2-thinking` | Yes | Boolean only |
| `qwen3` | Yes | Boolean only |

## Streaming with Thinking

Stream thinking and response chunks separately:

```elixir
{:ok, stream} = Ollama.chat(client,
  model: "deepseek-r1:1.5b",
  messages: [%{role: "user", content: "Explain recursion step by step."}],
  think: true,
  stream: true
)

stream
|> Stream.each(fn chunk ->
  if thinking = get_in(chunk, ["message", "thinking"]) do
    IO.write("[thinking] #{thinking}")
  end
  if content = get_in(chunk, ["message", "content"]) do
    IO.write(content)
  end
end)
|> Stream.run()
```

## Thinking with Typed Responses

```elixir
{:ok, response} = Ollama.chat(client,
  model: "deepseek-r1:1.5b",
  messages: [%{role: "user", content: "What is 15 * 23?"}],
  think: true,
  response_format: :struct
)

IO.puts("Thinking: #{response.message.thinking}")
IO.puts("Answer: #{response.message.content}")
```

## Completion with Thinking

Thinking also works with the completion endpoint:

```elixir
{:ok, response} = Ollama.completion(client,
  model: "deepseek-r1:1.5b",
  prompt: "Calculate the factorial of 7, showing your work.",
  think: true
)

IO.puts("Thinking: #{response["thinking"]}")
IO.puts("Response: #{response["response"]}")
```

## Error Handling

Not all models support thinking. Handle unsupported models gracefully:

```elixir
case Ollama.chat(client, model: model, messages: messages, think: true) do
  {:ok, response} ->
    response

  {:error, %Ollama.ResponseError{status: 400}} ->
    # Model doesn't support thinking, retry without
    {:ok, response} = Ollama.chat(client, model: model, messages: messages)
    response

  {:error, error} ->
    raise "Request failed: #{inspect(error)}"
end
```

## Performance Considerations

- Thinking increases response time and token usage
- Use `"low"` for simple problems to reduce latency
- Use `"high"` only when deep reasoning is needed
- Consider disabling thinking for straightforward queries

## Best Practices

1. **Match level to complexity** - Don't use high thinking for simple questions
2. **Stream long responses** - Thinking can produce lengthy output
3. **Handle unsupported models** - Not all models support thinking
4. **Consider token costs** - Thinking tokens count toward usage

## See Also

- [Streaming Guide](streaming.md) - Real-time thinking output
- [Examples](../examples/README.md) - Working thinking examples
