# Create Custom Model Example
# Run with:
#   elixir examples/model_management/create_custom.exs
#   RUN_CREATE_MODEL=1 mix run examples/model_management/create_custom.exs

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
name = "ollama-ex-demo"

base_model = "llama3.2"
system_prompt = "You are a concise assistant who answers in one sentence."

models_from_response = fn
  %{"models" => models} when is_list(models) -> models
  %{models: models} when is_list(models) -> models
  _ -> []
end

model_name = fn
  %{"name" => name} -> name
  %{name: name} -> name
  _ -> nil
end

run_demo = fn client, model ->
  case Ollama.chat(client,
         model: model,
         messages: [%{role: "user", content: "Say hello in one sentence."}]
       ) do
    {:ok, response} ->
      IO.puts("Demo response: #{get_in(response, ["message", "content"])}")

    {:error, error} ->
      IO.puts("Demo request failed: #{inspect(error)}")
  end
end

with {:ok, res} <- Ollama.list_models(client),
     models <- models_from_response.(res),
     false <- Enum.any?(models, fn model -> model_name.(model) == name end) do
  if System.get_env("RUN_CREATE_MODEL") == "1" do
    case Ollama.create_model(client, name: name, from: base_model, system: system_prompt) do
      {:ok, response} ->
        IO.inspect(response, label: "Create response")
        run_demo.(client, name)

      {:error, error} ->
        IO.puts("Create failed: #{inspect(error)}")
    end
  else
    IO.puts(
      "Skipping create_model (this writes a new local model). " <>
        "Set RUN_CREATE_MODEL=1 to create #{name}."
    )
  end
else
  true ->
    IO.puts("Model #{name} already exists. Delete it to recreate.")
    IO.puts("Try it with: mix run examples/basic/chat.exs (set model: #{name})")

  {:error, reason} ->
    IO.puts("Failed to list models: #{inspect(reason)}")
end
