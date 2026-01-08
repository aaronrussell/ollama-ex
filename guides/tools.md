# Tool Use (Function Calling)

Ollama supports tool use for models that are trained for it. This allows
the model to request function calls that your code executes.

## Overview

The tool use workflow:

1. Define tools with JSON Schema
2. Send chat with tool definitions
3. Model returns tool_calls (if needed)
4. Execute the functions
5. Send results back to model
6. Model generates final response

## Defining Tools

Tools use JSON Schema format:

```elixir
weather_tool = %{
  type: "function",
  function: %{
    name: "get_weather",
    description: "Get current weather for a location",
    parameters: %{
      type: "object",
      properties: %{
        location: %{
          type: "string",
          description: "City name, e.g., 'San Francisco'"
        },
        unit: %{
          type: "string",
          enum: ["celsius", "fahrenheit"],
          description: "Temperature unit"
        }
      },
      required: ["location"]
    }
  }
}
```

## Tool Helpers

You can define tools programmatically:

```elixir
tool =
  Ollama.Tool.define(:get_weather,
    description: "Get current weather for a location",
    parameters: [
      location: [type: :string, required: true, description: "City name"],
      unit: [type: :string, enum: ["celsius", "fahrenheit"]]
    ]
  )
```

Or pass functions directly and let Ollama convert them:

```elixir
defmodule WeatherTools do
  @doc "Get weather for a city."
  @spec get_weather(String.t(), String.t()) :: String.t()
  def get_weather(city, unit), do: "#{city} in #{unit}: 72 degrees"
end

{:ok, response} = Ollama.chat(client,
  model: "llama3.2",
  messages: [%{role: "user", content: "Weather in Tokyo?"}],
  tools: [&WeatherTools.get_weather/2]
)
```

Ollama also ships predefined tool definitions for web search and fetch:

```elixir
tools = Ollama.Web.Tools.all()
```

### Best Practices for Tool Definitions

1. **Clear descriptions** - Help the model understand when to use the tool
2. **Specific parameter descriptions** - Include examples and constraints
3. **Required fields** - Mark truly required parameters
4. **Enum values** - Use enums for constrained choices

## Basic Workflow

```elixir
defmodule WeatherAgent do
  def run(question) do
    client = Ollama.init()
    tools = [weather_tool()]

    # Step 1: Initial request
    {:ok, response} = Ollama.chat(client,
      model: "llama3.2",
      messages: [%{role: "user", content: question}],
      tools: tools
    )

    # Step 2: Check for tool calls
    case get_in(response, ["message", "tool_calls"]) do
      nil ->
        # No tool call, return direct response
        response["message"]["content"]

      tool_calls ->
        # Step 3: Execute tools
        results = execute_tools(tool_calls)

        # Step 4: Send results back
        {:ok, final} = Ollama.chat(client,
          model: "llama3.2",
          messages: [
            %{role: "user", content: question},
            %{role: "assistant", content: "", tool_calls: tool_calls},
            %{role: "tool", content: results}
          ],
          tools: tools
        )

        final["message"]["content"]
    end
  end

  defp execute_tools(tool_calls) do
    # Execute each tool and collect results
    tool_calls
    |> Enum.map(&execute_tool/1)
    |> Enum.join("\n")
  end

  defp execute_tool(%{"function" => %{"name" => "get_weather", "arguments" => args}}) do
    # Your actual weather API call here
    location = args["location"]
    "Weather in #{location}: 72°F, sunny"
  end
end
```

## Multi-Turn Tool Use

For complex tasks, the model may need multiple tool calls:

```elixir
defmodule Agent do
  @max_iterations 5

  def run(prompt, tools) do
    client = Ollama.init()
    messages = [%{role: "user", content: prompt}]
    loop(client, messages, tools, 0)
  end

  defp loop(_client, messages, _tools, @max_iterations) do
    {:error, :max_iterations}
  end

  defp loop(client, messages, tools, iteration) do
    {:ok, response} = Ollama.chat(client,
      model: "llama3.2",
      messages: messages,
      tools: tools
    )

    case get_in(response, ["message", "tool_calls"]) do
      nil ->
        {:ok, response["message"]["content"]}

      tool_calls ->
        results = execute_all(tool_calls)

        messages = messages ++
          [%{role: "assistant", content: "", tool_calls: tool_calls}] ++
          Enum.map(results, &%{role: "tool", content: &1})

        loop(client, messages, tools, iteration + 1)
    end
  end
end
```

## Web Tools Integration

Use predefined web tools for search and fetch:

```elixir
# Get all web tool definitions
tools = Ollama.Web.Tools.all()

{:ok, response} = Ollama.chat(client,
  model: "llama3.2",
  messages: [%{role: "user", content: "Search for Elixir news"}],
  tools: tools
)

# Execute web tool calls
case get_in(response, ["message", "tool_calls"]) do
  [%{"function" => %{"name" => "web_search", "arguments" => args}}] ->
    {:ok, results} = Ollama.web_search(client, query: args["query"])
    # Continue with results...

  [%{"function" => %{"name" => "web_fetch", "arguments" => args}}] ->
    {:ok, page} = Ollama.web_fetch(client, url: args["url"])
    # Continue with page content...

  _ ->
    response["message"]["content"]
end
```

## Thinking with Tools

Combine tool use with thinking mode (supported models only):

```elixir
{:ok, response} = Ollama.chat(client,
  model: "gpt-oss:20b-cloud",
  messages: [%{role: "user", content: "Calculate the weather impact on crops"}],
  tools: [weather_tool, crop_tool],
  think: true
)

# Access thinking process
IO.puts("Thinking: #{response["message"]["thinking"]}")

# Handle tool calls as usual
tool_calls = get_in(response, ["message", "tool_calls"])
```

## Tool Argument Handling

Tool arguments may arrive as a map or JSON string. Handle both:

```elixir
defp parse_arguments(args) when is_map(args), do: args
defp parse_arguments(args) when is_binary(args) do
  case Jason.decode(args) do
    {:ok, parsed} -> parsed
    {:error, _} -> %{}
  end
end

defp execute_tool(%{"function" => %{"name" => name, "arguments" => args}}) do
  parsed_args = parse_arguments(args)
  # Use parsed_args...
end
```

## Error Handling

Handle tool execution failures gracefully:

```elixir
defp execute_tool_safely(tool_call) do
  try do
    result = execute_tool(tool_call)
    Jason.encode!(%{success: true, result: result})
  rescue
    e ->
      Jason.encode!(%{success: false, error: Exception.message(e)})
  end
end

# In the agent loop, send error back to model
{:ok, response} = Ollama.chat(client,
  model: "llama3.2",
  messages: messages ++ [
    %{role: "assistant", content: "", tool_calls: tool_calls},
    %{role: "tool", content: ~s({"success": false, "error": "API unavailable"})}
  ],
  tools: tools
)
```

## Limitations

- **No streaming with tools** - `stream: true` is not supported when using tools
- **Model dependent** - Not all models support tool use
- **Tool arguments** - Arguments may arrive as a JSON string or a map
- **Non-deterministic** - Tool calls may vary between runs

## Compatible Models

| Model | Tool Support | Thinking + Tools |
|-------|--------------|------------------|
| llama3.2 | Yes | No |
| mistral | Yes | No |
| mixtral | Yes | No |
| command-r | Yes | No |
| qwen2.5 | Yes | No |
| qwen3 | Yes | Yes |
| gpt-oss:20b-cloud | Yes | Yes |
| gpt-oss:120b-cloud | Yes | Yes |

## See Also

- [Cloud API Guide](cloud-api.md) - Web search and fetch details
- [Thinking Guide](thinking.md) - Thinking mode with tools
- [Examples](../examples/README.md) - Working tool examples
