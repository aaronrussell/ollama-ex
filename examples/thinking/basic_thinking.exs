# Thinking Mode Example
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

model = "deepseek-r1:1.5b"

messages = [
  %{
    role: "user",
    content: "What is 12 * 7? Show your reasoning, then give the final number."
  }
]

response =
  case Ollama.chat(client,
         model: model,
         messages: messages,
         think: true,
         options: [temperature: 0]
       ) do
    {:ok, response} ->
      response

    {:error, %{status: 400}} ->
      IO.puts(
        "Thinking not supported by #{model}; retrying without think. " <>
          "Use a model that supports `think` to see thinking output."
      )

      case Ollama.chat(client, model: model, messages: messages, options: [temperature: 0]) do
        {:ok, response} -> response
        {:error, error} -> raise "Ollama request failed: #{inspect(error)}"
      end

    {:error, error} ->
      raise "Ollama request failed: #{inspect(error)}"
  end

if thinking = get_in(response, ["message", "thinking"]) do
  IO.puts("=== Thinking ===")
  IO.puts(thinking)
  IO.puts("")
end

IO.puts("=== Response ===")
IO.puts(response["message"]["content"])
