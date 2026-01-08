# Basic Show Model Example
# Run with: elixir examples/basic/show_model.exs

root = Path.expand("../..", __DIR__)

ollama_dep =
  if File.exists?(Path.join(root, "mix.exs")) do
    {:ollama, path: root}
  else
    {:ollama, "~> 0.10.0"}
  end

Mix.install([ollama_dep])

client = Ollama.init()

with {:ok, %{"models" => models}} <- Ollama.list_models(client),
     [model | _] <- models,
     {:ok, info} <- Ollama.show_model(client, name: model["name"]) do
  IO.puts("Model: #{model["name"]}")
  IO.puts("Format: #{get_in(info, ["details", "format"]) || "unknown"}")
  IO.puts("Family: #{get_in(info, ["details", "family"]) || "unknown"}")
else
  [] ->
    IO.puts("No models found. Run `ollama pull llama3.2` and try again.")

  {:error, reason} ->
    IO.puts("Failed to show model: #{inspect(reason)}")
end
