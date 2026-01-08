# System Prompt Example
# Run with: elixir examples/conversations/system_prompts.exs

root = Path.expand("../..", __DIR__)

ollama_dep =
  if File.exists?(Path.join(root, "mix.exs")) do
    {:ollama, path: root}
  else
    {:ollama, "~> 0.10.0"}
  end

Mix.install([ollama_dep])

client = Ollama.init()

messages = [
  %{role: "system", content: "You are a friendly travel guide. Keep answers under 3 sentences."},
  %{role: "user", content: "What should I see in Kyoto?"}
]

{:ok, response} =
  Ollama.chat(client,
    model: "llama3.2",
    messages: messages
  )

IO.puts(response["message"]["content"])
