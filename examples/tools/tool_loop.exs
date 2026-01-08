# Agentic Tool Loop Example
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
  Mix.install([ollama_dep, {:jason, "~> 1.4"}])
end

defmodule ToolAgent do
  @tools [
    %{
      type: "function",
      function: %{
        name: "calculator",
        description: "Perform arithmetic calculations",
        parameters: %{
          type: "object",
          properties: %{
            expression: %{type: "string", description: "Math expression to evaluate"}
          },
          required: ["expression"]
        }
      }
    },
    %{
      type: "function",
      function: %{
        name: "get_date",
        description: "Get the current date",
        parameters: %{type: "object", properties: %{}}
      }
    }
  ]

  def run(prompt) do
    client = Ollama.init()
    messages = [%{role: "user", content: prompt}]
    loop(client, messages, 0)
  end

  defp loop(_client, _messages, iterations) when iterations > 5 do
    IO.puts("Max iterations reached")
  end

  defp loop(client, messages, iterations) do
    {:ok, response} =
      Ollama.chat(client,
        model: "llama3.2",
        messages: messages,
        tools: @tools
      )

    case get_in(response, ["message", "tool_calls"]) do
      nil ->
        IO.puts("Final: #{response["message"]["content"]}")

      tool_calls ->
        IO.puts("Iteration #{iterations + 1}: Calling #{length(tool_calls)} tool(s)")

        results = Enum.map(tool_calls, &execute_tool/1)

        messages =
          messages ++
            [%{role: "assistant", content: "", tool_calls: tool_calls}] ++
            Enum.map(results, fn result -> %{role: "tool", content: result} end)

        loop(client, messages, iterations + 1)
    end
  end

  defp execute_tool(%{"function" => %{"name" => "calculator", "arguments" => args}}) do
    # WARNING: Never eval untrusted input in production!
    args = decode_args(args)
    expr = Map.get(args, "expression", "")

    if expr == "" do
      "Missing expression"
    else
      try do
        {result, _} = Code.eval_string(expr)
        to_string(result)
      rescue
        _ -> "Error evaluating expression"
      end
    end
  end

  defp execute_tool(%{"function" => %{"name" => "get_date"}}) do
    Date.utc_today() |> to_string()
  end

  defp execute_tool(_), do: "Unsupported tool call"

  defp decode_args(args) when is_map(args), do: args

  defp decode_args(args) when is_binary(args) do
    case Jason.decode(args) do
      {:ok, decoded} when is_map(decoded) -> decoded
      _ -> %{}
    end
  end

  defp decode_args(_), do: %{}
end

ToolAgent.run("What is 15 * 37 + 42? Also, what's today's date?")
