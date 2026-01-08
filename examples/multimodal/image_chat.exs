# Multimodal Chat Example (Image + Text)
# Run with: elixir examples/multimodal/image_chat.exs

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
model = "llava"

unload_others = fn ->
  case Ollama.list_running(client) do
    {:ok, %{"models" => models}} when is_list(models) ->
      Enum.each(models, fn model_info ->
        name = Map.get(model_info, "name") || Map.get(model_info, :name)

        if is_binary(name) and not String.starts_with?(name, model) do
          Ollama.unload(client, model: name)
        end
      end)

    {:ok, %{models: models}} when is_list(models) ->
      Enum.each(models, fn model_info ->
        name = Map.get(model_info, "name") || Map.get(model_info, :name)

        if is_binary(name) and not String.starts_with?(name, model) do
          Ollama.unload(client, model: name)
        end
      end)

    _ ->
      :ok
  end
end

with {:ok, %{"models" => models}} <- Ollama.list_models(client),
     true <-
       Enum.any?(models, fn model_info -> String.starts_with?(model_info["name"], model) end) do
  image_path = Path.expand("../../media/poster.png", __DIR__)
  base_options = [num_ctx: 2048]

  if File.exists?(image_path) do
    case Ollama.chat(client,
           model: model,
           messages: [
             %{role: "user", content: "Describe this image.", images: [image_path]}
           ],
           options: base_options
         ) do
      {:ok, response} ->
        IO.puts(response["message"]["content"])

      {:error, error} when is_struct(error, Ollama.ResponseError) ->
        if error.status == 500 do
          IO.puts("Model runner stopped (HTTP 500). Attempting recovery...")
          IO.puts("Attempting to free resources by unloading other running models...")
          unload_others.()
          IO.puts("Retrying on CPU (options: [num_gpu: 0, num_ctx: 1024])...")

          case Ollama.chat(client,
                 model: model,
                 messages: [
                   %{role: "user", content: "Describe this image.", images: [image_path]}
                 ],
                 options: [num_gpu: 0, num_ctx: 1024]
               ) do
            {:ok, response} ->
              IO.puts(response["message"]["content"])

            {:error, _retry_error} ->
              IO.puts("""
              Skipping multimodal example. The model runner stopped again.
              Check Ollama server logs for details.
              """)
          end
        else
          IO.puts("Image chat failed: HTTP #{error.status} - #{error.message}")
        end

      {:error, error} ->
        IO.puts("Image chat failed: #{inspect(error)}")
    end
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
