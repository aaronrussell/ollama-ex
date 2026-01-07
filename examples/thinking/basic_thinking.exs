# Thinking Mode Example
Mix.install([{:ollama, "~> 0.9"}])

client = Ollama.init()

{:ok, response} =
  Ollama.chat(client,
    # Or other thinking-capable model
    model: "qwen2.5:7b",
    messages: [
      %{role: "user", content: "How many Rs are in the word 'strawberry'?"}
    ],
    think: true
  )

if thinking = get_in(response, ["message", "thinking"]) do
  IO.puts("=== Thinking ===")
  IO.puts(thinking)
  IO.puts("")
end

IO.puts("=== Response ===")
IO.puts(response["message"]["content"])
