# Single Embedding Example
# Run with: elixir examples/embeddings/single_embed.exs

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
  Ollama.embed(client,
    model: "nomic-embed-text",
    input: "Why is the sky blue?"
  )

embedding = response["embeddings"] |> List.first()
IO.puts("Embedding dimensions: #{length(embedding)}")
