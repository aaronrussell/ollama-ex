root = Path.expand("../..", __DIR__)

ollama_dep =
  if File.exists?(Path.join(root, "mix.exs")) do
    {:ollama, path: root}
  else
    {:ollama, "~> 0.10.0"}
  end

Mix.install([ollama_dep])

client = Ollama.init()
{:ok, %{"models" => models}} = Ollama.list_models(client)

for model <- models do
  size_gb = model["size"] / 1_000_000_000
  IO.puts("#{model["name"]} (#{Float.round(size_gb, 2)} GB)")
end
