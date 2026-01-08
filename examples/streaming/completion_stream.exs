# Streaming Completion Example
# Run with: elixir examples/streaming/completion_stream.exs

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
