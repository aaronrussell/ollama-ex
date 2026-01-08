# Context Continuation Example
# Run with: elixir examples/conversations/context_continuation.exs

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

{:ok, first} =
  Ollama.completion(client,
    model: "llama3.2",
    prompt: "List three fun facts about the moon, one short sentence each:\n1.",
    options: [num_predict: 200, temperature: 0]
  )

IO.puts("=== First Response ===")
IO.puts(first["response"])

{:ok, second} =
  Ollama.completion(client,
    model: "llama3.2",
    prompt:
      "Continue the list with items 4-6 only, one short sentence each. " <>
        "Do not repeat items 1-3.\n4.",
    context: first["context"],
    options: [num_predict: 200, temperature: 0]
  )

IO.puts("\n=== Continued Response ===")
IO.puts(second["response"])
