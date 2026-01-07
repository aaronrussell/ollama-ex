# Streaming Chat Example
Mix.install([{:ollama, "~> 0.9"}])

client = Ollama.init()

{:ok, stream} =
  Ollama.chat(client,
    model: "llama3.2",
    messages: [%{role: "user", content: "Tell me a short story"}],
    stream: true
  )

stream
|> Stream.each(fn chunk ->
  if content = get_in(chunk, ["message", "content"]) do
    IO.write(content)
  end
end)
|> Stream.run()

# Final newline
IO.puts("")
