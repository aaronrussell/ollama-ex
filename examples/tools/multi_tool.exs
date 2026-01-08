# Multiple Tools Example
# Run with: elixir examples/tools/multi_tool.exs

root = Path.expand("../..", __DIR__)

ollama_dep =
  if File.exists?(Path.join(root, "mix.exs")) do
    {:ollama, path: root}
  else
    {:ollama, "~> 0.10.0"}
  end

Mix.install([ollama_dep])

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

{:ok, response} =
  Ollama.chat(client,
    model: "llama3.2",
    messages: [%{role: "user", content: "What time is it and what is 9*9?"}],
    tools: [calculator, get_time]
  )

case get_in(response, ["message", "tool_calls"]) do
  nil ->
    IO.puts("No tool calls. Response: #{response["message"]["content"]}")

  tool_calls ->
    IO.inspect(tool_calls, label: "Tool calls")
    IO.puts("Execute the tools locally and send results back as tool messages.")
end
