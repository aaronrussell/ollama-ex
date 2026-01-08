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
  @required_tools ["calculator", "get_date"]
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

    messages = [
      %{
        role: "system",
        content:
          "You must use the provided tools to answer. " <>
            "Always call calculator for math and get_date for the current date. " <>
            "Do not answer directly until the tools are called."
      },
      %{role: "user", content: prompt}
    ]

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
        tools: @tools,
        options: [temperature: 0]
      )

    tool_calls = get_in(response, ["message", "tool_calls"])
    tool_calls = if is_list(tool_calls), do: tool_calls, else: []

    case tool_calls do
      [] ->
        if iterations < 2 do
          IO.puts("No tool calls yet; retrying with a stronger instruction...")

          messages =
            messages ++
              [
                %{role: "assistant", content: response["message"]["content"] || ""},
                %{
                  role: "user",
                  content:
                    "You must call the tools. Call calculator and get_date now. " <>
                      "Do not answer until you do."
                }
              ]

          loop(client, messages, iterations + 1)
        else
          IO.puts("Final: #{response["message"]["content"]}")
        end

      _ ->
        IO.puts("Iteration #{iterations + 1}: Calling #{length(tool_calls)} tool(s)")

        tool_results =
          Enum.map(tool_calls, fn tool_call ->
            tool_name = get_in(tool_call, ["function", "name"]) || "unknown"
            %{role: "tool", tool_name: tool_name, content: execute_tool(tool_call)}
          end)

        called_tools =
          tool_calls
          |> Enum.map(&get_in(&1, ["function", "name"]))
          |> Enum.filter(&is_binary/1)

        missing_tools = Enum.reject(@required_tools, &(&1 in called_tools))

        messages =
          messages ++
            [
              %{
                role: "assistant",
                content: response["message"]["content"] || "",
                tool_calls: tool_calls
              }
            ] ++ tool_results

        messages =
          if missing_tools == [] do
            messages
          else
            messages ++
              [
                %{
                  role: "user",
                  content:
                    "You still need to call the following tools: #{Enum.join(missing_tools, ", ")}. " <>
                      "Call them now and then provide the final answer."
                }
              ]
          end

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
