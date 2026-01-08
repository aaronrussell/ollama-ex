# Options and Presets Example
# Run with: elixir examples/advanced/options_presets.exs

root = Path.expand("../..", __DIR__)

ollama_dep =
  if File.exists?(Path.join(root, "mix.exs")) do
    {:ollama, path: root}
  else
    {:ollama, "~> 0.10.0"}
  end

Mix.install([ollama_dep])

client = Ollama.init()

opts =
  Ollama.Options.Presets.creative()
  |> Ollama.Options.temperature(0.9)
  |> Ollama.Options.top_p(0.95)

{:ok, response} =
  Ollama.chat(client,
    model: "llama3.2",
    messages: [%{role: "user", content: "Write a playful haiku about rain."}],
    options: opts
  )

IO.puts(response["message"]["content"])
