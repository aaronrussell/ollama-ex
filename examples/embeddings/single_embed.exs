# Single Embedding Example
# Run with: elixir examples/embeddings/single_embed.exs

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

{:ok, response} =
  Ollama.embed(client,
    model: "nomic-embed-text",
    input: "Why is the sky blue?"
  )

embedding = response["embeddings"] |> List.first()
IO.puts("Embedding dimensions: #{length(embedding)}")
