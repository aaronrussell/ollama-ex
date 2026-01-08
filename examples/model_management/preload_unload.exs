# Preload/Unload Example
# Run with: elixir examples/model_management/preload_unload.exs

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
model = "llama3.2"

case Ollama.preload(client, model: model) do
  {:ok, true} -> IO.puts("Preloaded #{model}")
  {:ok, false} -> IO.puts("Model not found: #{model}")
  {:error, err} -> IO.puts("Preload failed: #{inspect(err)}")
end

case Ollama.unload(client, model: model) do
  {:ok, true} -> IO.puts("Unloaded #{model}")
  {:ok, false} -> IO.puts("Model not found: #{model}")
  {:error, err} -> IO.puts("Unload failed: #{inspect(err)}")
end
