# Streaming Chat Example
root = Path.expand("../..", __DIR__)

ollama_dep =
  if File.exists?(Path.join(root, "mix.exs")) do
    {:ollama, path: root}
  else
    {:ollama, "~> 0.10.0"}
  end

Mix.install([ollama_dep])

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
