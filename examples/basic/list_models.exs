Mix.install([{:ollama, "~> 0.9"}])

client = Ollama.init()
{:ok, %{"models" => models}} = Ollama.list_models(client)

for model <- models do
  size_gb = model["size"] / 1_000_000_000
  IO.puts("#{model["name"]} (#{Float.round(size_gb, 2)} GB)")
end
