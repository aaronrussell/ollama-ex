# Create Custom Model Example
# Run with: elixir examples/model_management/create_custom.exs

root = Path.expand("../..", __DIR__)

ollama_dep =
  if File.exists?(Path.join(root, "mix.exs")) do
    {:ollama, path: root}
  else
    {:ollama, "~> 0.10.0"}
  end

Mix.install([ollama_dep])

client = Ollama.init()
name = "ollama-ex-demo"

modelfile = """
FROM llama3.2
SYSTEM You are a concise assistant who answers in one sentence.
"""

with {:ok, %{"models" => models}} <- Ollama.list_models(client),
     false <- Enum.any?(models, fn model -> model["name"] == name end) do
  if System.get_env("RUN_CREATE_MODEL") == "1" do
    {:ok, response} = Ollama.create_model(client, name: name, modelfile: modelfile)
    IO.inspect(response, label: "Create response")
  else
    IO.puts(
      "Skipping create_model (this writes a new local model). " <>
        "Set RUN_CREATE_MODEL=1 to create #{name}."
    )
  end
else
  true ->
    IO.puts("Model #{name} already exists. Delete it to recreate.")

  {:error, reason} ->
    IO.puts("Failed to list models: #{inspect(reason)}")
end
