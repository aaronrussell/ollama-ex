# Batch Embeddings Example
# Run with: elixir examples/embeddings/batch_embed.exs

root = Path.expand("../..", __DIR__)

ollama_dep =
  if File.exists?(Path.join(root, "mix.exs")) do
    {:ollama, path: root}
  else
    {:ollama, "~> 0.10.0"}
  end

Mix.install([ollama_dep])

client = Ollama.init()

inputs = [
  "The cat sat on the mat.",
  "A dog chased a ball.",
  "The ocean is calm today."
]

{:ok, response} =
  Ollama.embed(client,
    model: "nomic-embed-text",
    input: inputs
  )

Enum.zip(inputs, response["embeddings"])
|> Enum.each(fn {text, embedding} ->
  IO.puts("#{String.slice(text, 0, 20)}... -> #{length(embedding)} dims")
end)
