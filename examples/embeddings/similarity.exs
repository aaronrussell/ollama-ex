# Semantic Similarity Example
Mix.install([{:ollama, "~> 0.9"}])

defmodule Similarity do
  def cosine(a, b) do
    dot = Enum.zip(a, b) |> Enum.map(fn {x, y} -> x * y end) |> Enum.sum()
    mag_a = :math.sqrt(Enum.map(a, &(&1 * &1)) |> Enum.sum())
    mag_b = :math.sqrt(Enum.map(b, &(&1 * &1)) |> Enum.sum())
    dot / (mag_a * mag_b)
  end
end

client = Ollama.init()

texts = [
  "The cat sat on the mat",
  "A feline rested on the rug",
  "The stock market crashed today",
  "Financial markets experienced a downturn"
]

{:ok, response} =
  Ollama.embed(client,
    model: "nomic-embed-text",
    input: texts
  )

embeddings = response["embeddings"]

IO.puts("Similarity Matrix:")
IO.puts("-" |> String.duplicate(60))

for {text1, emb1, i} <- Enum.with_index(Enum.zip(texts, embeddings)) do
  for {text2, emb2, j} <- Enum.with_index(Enum.zip(texts, embeddings)), j > i do
    sim = Similarity.cosine(emb1, emb2)

    IO.puts(
      "#{Float.round(sim, 3)} | \"#{String.slice(text1, 0, 25)}...\" vs \"#{String.slice(text2, 0, 25)}...\""
    )
  end
end
