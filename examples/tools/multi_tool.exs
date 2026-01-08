# Multiple Tools Example
# Run with: elixir examples/tools/multi_tool.exs

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

calculator =
  Ollama.Tool.define(:calculator,
    description: "Evaluate a basic math expression",
    parameters: [
      expression: [type: :string, required: true, description: "Expression like 12 * 7"]
    ]
  )

get_time =
  Ollama.Tool.define(:get_time,
    description: "Get the current time in ISO8601",
    parameters: []
  )

system_message = %{
  role: "system",
  content:
    "You must call both tools (calculator and get_time) before answering. " <>
      "Do not answer until the tools are called."
}

user_message = %{role: "user", content: "What time is it and what is 9*9?"}

messages = [system_message, user_message]

request = fn msgs ->
  Ollama.chat(client,
    model: "llama3.2",
    messages: msgs,
    tools: [calculator, get_time],
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
            %{
              role: "user",
              content: "Call calculator and get_time now. Do not answer without them."
            }
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
    IO.puts("No tool calls. Response: #{response["message"]["content"]}")

  _ ->
    IO.inspect(tool_calls, label: "Tool calls")
    IO.puts("Execute the tools locally and send results back as tool messages.")
end
