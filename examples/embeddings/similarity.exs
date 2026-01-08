# Semantic Similarity Example
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
pairs = Enum.zip(texts, embeddings)

IO.puts("Similarity Matrix:")
IO.puts("-" |> String.duplicate(60))

for {{text1, emb1}, i} <- Enum.with_index(pairs) do
  for {{text2, emb2}, j} <- Enum.with_index(pairs), j > i do
    sim = Similarity.cosine(emb1, emb2)

    IO.puts(
      "#{Float.round(sim, 3)} | \"#{String.slice(text1, 0, 25)}...\" vs \"#{String.slice(text2, 0, 25)}...\""
    )
  end
end
