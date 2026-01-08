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

system_message = %{
  role: "system",
  content:
    "You must call the get_weather tool to answer. " <>
      "Do not respond with the weather until you call the tool."
}

user_message = %{role: "user", content: "What's the weather in Tokyo?"}

messages = [system_message, user_message]

request = fn msgs ->
  Ollama.chat(client,
    model: "llama3.2",
    messages: msgs,
    tools: [weather_tool],
    options: [temperature: 0]
  )
end

{:ok, response} = request.(messages)

tool_calls =
  case get_in(response, ["message", "tool_calls"]) do
    calls when is_list(calls) -> calls
    _ -> []
  end

{response, tool_calls} =
  if tool_calls == [] do
    {:ok, retry} =
      request.(
        messages ++
          [
            %{role: "assistant", content: response["message"]["content"] || ""},
            %{role: "user", content: "Call get_weather now. Do not answer without it."}
          ]
      )

    retry_calls =
      case get_in(retry, ["message", "tool_calls"]) do
        calls when is_list(calls) -> calls
        _ -> []
      end

    {retry, retry_calls}
  else
    {response, tool_calls}
  end

case tool_calls do
  [] ->
    IO.puts("No tool call: #{response["message"]["content"]}")

  _ ->
    IO.inspect(tool_calls, label: "Tool calls")

    # Simulate tool execution
    tool_result = Jason.encode!(%{temperature: 22, condition: "sunny"})

    # Second request with tool result
    {:ok, final} =
      Ollama.chat(client,
        model: "llama3.2",
        messages: [
          system_message,
          user_message,
          %{role: "assistant", content: "", tool_calls: tool_calls},
          %{role: "tool", tool_name: "get_weather", content: tool_result}
        ],
        tools: [weather_tool],
        options: [temperature: 0]
      )

    IO.puts("Final response: #{final["message"]["content"]}")
end
