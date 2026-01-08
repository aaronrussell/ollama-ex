# Concurrent Requests Example
# Run with: elixir examples/advanced/concurrent_requests.exs

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

prompts = [
  "What is photosynthesis?",
  "Explain gravity in simple terms",
  "What causes rainbows?",
  "How do magnets work?"
]

results =
  prompts
  |> Task.async_stream(
    fn prompt ->
      {:ok, response} =
        Ollama.chat(client,
          model: "llama3.2",
          messages: [%{role: "user", content: prompt}]
        )

      {prompt, response["message"]["content"]}
    end,
    max_concurrency: 2,
    timeout: 60_000
  )
  |> Enum.map(fn {:ok, result} -> result end)

for {prompt, response} <- results do
  IO.puts("\n=== #{prompt} ===")
  IO.puts(String.slice(response, 0, 200) <> "...")
end
