# Context Continuation Example
# Run with: elixir examples/conversations/context_continuation.exs

root = Path.expand("../..", __DIR__)

ollama_dep =
  if File.exists?(Path.join(root, "mix.exs")) do
    {:ollama, path: root}
  else
    {:ollama, "~> 0.10.0"}
  end

Mix.install([ollama_dep])

client = Ollama.init()

{:ok, first} =
  Ollama.completion(client,
    model: "llama3.2",
    prompt: "List three fun facts about the moon:\n1.",
    options: [num_predict: 120]
  )

IO.puts("=== First Response ===")
IO.puts(first["response"])

{:ok, second} =
  Ollama.completion(client,
    model: "llama3.2",
    prompt: "Continue the list:\n4.",
    context: first["context"],
    options: [num_predict: 120]
  )

IO.puts("\n=== Continued Response ===")
IO.puts(second["response"])
