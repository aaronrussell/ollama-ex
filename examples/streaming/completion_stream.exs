# Streaming Completion Example
# Run with: elixir examples/streaming/completion_stream.exs

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
  Ollama.completion(client,
    model: "llama3.2",
    prompt: "Write a short poem about the ocean.",
    stream: true
  )

stream
|> Stream.each(fn chunk ->
  if content = chunk["response"] do
    IO.write(content)
  end
end)
|> Stream.run()

IO.puts("")
