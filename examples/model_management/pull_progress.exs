# Pull Model with Progress Example
# Run with: elixir examples/model_management/pull_progress.exs

root = Path.expand("../..", __DIR__)

ollama_dep =
  if File.exists?(Path.join(root, "mix.exs")) do
    {:ollama, path: root}
  else
    {:ollama, "~> 0.10.0"}
  end

Mix.install([ollama_dep])

client = Ollama.init()
model = "llama3.2"

IO.puts("Pulling #{model} (this may take a while on first run)...")

{:ok, stream} = Ollama.pull_model(client, name: model, stream: true)

stream
|> Stream.each(fn chunk ->
  status = chunk["status"] || "working"

  line =
    case {chunk["completed"], chunk["total"]} do
      {completed, total} when is_number(completed) and is_number(total) and total > 0 ->
        percent = Float.round(completed / total * 100, 1)
        "#{status} (#{percent}%)"

      _ ->
        status
    end

  IO.puts(line)
end)
|> Stream.run()

IO.puts("Done.")
