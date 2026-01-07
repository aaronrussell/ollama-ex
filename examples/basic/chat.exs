# Basic Chat Example
# Run with: elixir examples/basic/chat.exs

Mix.install([{:ollama, "~> 0.9"}])

client = Ollama.init()

{:ok, response} =
  Ollama.chat(client,
    model: "llama3.2",
    messages: [
      %{role: "user", content: "Why is the sky blue?"}
    ]
  )

IO.puts(response["message"]["content"])
