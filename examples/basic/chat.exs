# Basic Chat Example
# Run with: elixir examples/basic/chat.exs

root = Path.expand("../..", __DIR__)

ollama_dep =
  if File.exists?(Path.join(root, "mix.exs")) do
    {:ollama, path: root}
  else
    {:ollama, "~> 0.10.0"}
  end

Mix.install([ollama_dep])

client = Ollama.init()

{:ok, response} =
  Ollama.chat(client,
    model: "llama3.2",
    messages: [
      %{role: "user", content: "Why is the sky blue?"}
    ]
  )

IO.puts(response["message"]["content"])
