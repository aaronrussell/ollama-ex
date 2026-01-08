# JSON Format Example
# Run with: elixir examples/structured/json_format.exs

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

{:ok, response} =
  Ollama.chat(client,
    model: "llama3.2",
    messages: [
      %{role: "user", content: "Return a JSON object with keys name and capital for Canada."}
    ],
    format: "json"
  )

json = response["message"]["content"]

case Jason.decode(json) do
  {:ok, data} -> IO.inspect(data, label: "Decoded JSON")
  {:error, reason} -> IO.puts("Failed to parse JSON: #{inspect(reason)}")
end
