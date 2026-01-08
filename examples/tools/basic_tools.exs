# Basic Tool Use Example
root = Path.expand("../..", __DIR__)

ollama_dep =
  if File.exists?(Path.join(root, "mix.exs")) do
    {:ollama, path: root}
  else
    {:ollama, "~> 0.10.0"}
  end

if Code.ensure_loaded?(Mix.Project) &&
     function_exported?(Mix.Project, :get, 0) &&
     Process.whereis(Mix.ProjectStack) &&
     Mix.Project.get() do
  :ok
else
  Mix.install([ollama_dep])
end

client = Ollama.init()

# Define a weather tool
weather_tool = %{
  type: "function",
  function: %{
    name: "get_weather",
    description: "Get the current weather for a location",
    parameters: %{
      type: "object",
      properties: %{
        location: %{type: "string", description: "City name"},
        unit: %{type: "string", enum: ["celsius", "fahrenheit"]}
      },
      required: ["location"]
    }
  }
}

# First request - model decides to call tool
{:ok, response} =
  Ollama.chat(client,
    model: "llama3.2",
    messages: [%{role: "user", content: "What's the weather in Tokyo?"}],
    tools: [weather_tool]
  )

# Check for tool calls
case get_in(response, ["message", "tool_calls"]) do
  nil ->
    IO.puts("No tool call: #{response["message"]["content"]}")

  tool_calls ->
    IO.inspect(tool_calls, label: "Tool calls")

    # Simulate tool execution
    tool_result = Jason.encode!(%{temperature: 22, condition: "sunny"})

    # Second request with tool result
    {:ok, final} =
      Ollama.chat(client,
        model: "llama3.2",
        messages: [
          %{role: "user", content: "What's the weather in Tokyo?"},
          %{role: "assistant", content: "", tool_calls: tool_calls},
          %{role: "tool", content: tool_result}
        ],
        tools: [weather_tool]
      )

    IO.puts("Final response: #{final["message"]["content"]}")
end
