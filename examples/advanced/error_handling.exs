# Error Handling Example
# Run with: elixir examples/advanced/error_handling.exs

root = Path.expand("../..", __DIR__)

ollama_dep =
  if File.exists?(Path.join(root, "mix.exs")) do
    {:ollama, path: root}
  else
    {:ollama, "~> 0.10.0"}
  end

Mix.install([ollama_dep])

client = Ollama.init()

IO.puts("=== Request Error Example ===")

case Ollama.chat(client, model: "llama3.2", messages: "not-a-list") do
  {:error, error} when is_struct(error, Ollama.RequestError) ->
    IO.puts("RequestError: #{Exception.message(error)}")

  other ->
    IO.inspect(other)
end

IO.puts("\n=== Response Error Example ===")

case Ollama.chat(client, model: "not-found", messages: [%{role: "user", content: "Hi"}]) do
  {:error, error} when is_struct(error, Ollama.ResponseError) ->
    IO.puts("ResponseError: #{Exception.message(error)}")
    IO.puts("Retryable? #{Ollama.Errors.retryable?(error)}")

  other ->
    IO.inspect(other)
end
