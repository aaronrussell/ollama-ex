# Multimodal Completion Example (Image + Text)
# Run with: elixir examples/multimodal/image_completion.exs

root = Path.expand("../..", __DIR__)

ollama_dep =
  if File.exists?(Path.join(root, "mix.exs")) do
    {:ollama, path: root}
  else
    {:ollama, "~> 0.10.0"}
  end

Mix.install([ollama_dep])

client = Ollama.init()
model = "llava"

with {:ok, %{"models" => models}} <- Ollama.list_models(client),
     true <-
       Enum.any?(models, fn model_info -> String.starts_with?(model_info["name"], model) end) do
  image_path = Path.expand("../../media/poster.webp", __DIR__)

  if File.exists?(image_path) do
    {:ok, response} =
      Ollama.completion(client,
        model: model,
        prompt: "Describe the image in one sentence.",
        images: [image_path]
      )

    IO.puts(response["response"])
  else
    IO.puts("Image not found at #{image_path}. Place an image there or update the path.")
  end
else
  {:ok, _} ->
    IO.puts("No multimodal model found. Pull one with: ollama pull llava")

  false ->
    IO.puts("No multimodal model found. Pull one with: ollama pull llava")

  {:error, reason} ->
    IO.puts("Failed to list models: #{inspect(reason)}")
end
