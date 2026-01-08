# Rate Limiting Example
# Run with: elixir examples/advanced/rate_limiting.exs

root = Path.expand("../..", __DIR__)

ollama_dep =
  if File.exists?(Path.join(root, "mix.exs")) do
    {:ollama, path: root}
  else
    {:ollama, "~> 0.10.0"}
  end

Mix.install([ollama_dep])

client = Ollama.init()

prompts = [
  "Give me one tip for better sleep.",
  "Give me one tip for focus.",
  "Give me one tip for exercise."
]

interval_ms = 750

prompts
|> Enum.with_index()
|> Enum.each(fn {prompt, idx} ->
  if idx > 0, do: Process.sleep(interval_ms)

  {:ok, response} =
    Ollama.chat(client,
      model: "llama3.2",
      messages: [%{role: "user", content: prompt}]
    )

  IO.puts("\n#{prompt}")
  IO.puts(String.trim(response["message"]["content"]))
end)
