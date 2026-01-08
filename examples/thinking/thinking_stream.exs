# Thinking Mode Streaming Example
# Run with: elixir examples/thinking/thinking_stream.exs

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
messages = [%{role: "user", content: "Count to 5 and explain your reasoning."}]

stream_result =
  Ollama.chat(client,
    model: model,
    messages: messages,
    think: true,
    stream: true
  )

run_stream = fn stream ->
  stream
  |> Stream.each(fn chunk ->
    if thinking = get_in(chunk, ["message", "thinking"]) do
      IO.write(thinking)
    end

    if content = get_in(chunk, ["message", "content"]) do
      IO.write(content)
    end
  end)
  |> Stream.run()

  IO.puts("")
end

case stream_result do
  {:ok, stream} ->
    try do
      run_stream.(stream)
    rescue
      error in Ollama.ResponseError ->
        if error.status == 400 do
          IO.puts("Thinking not supported by this model; streaming without think.")

          {:ok, fallback_stream} =
            Ollama.chat(client,
              model: model,
              messages: messages,
              stream: true
            )

          run_stream.(fallback_stream)
        else
          reraise error, __STACKTRACE__
        end
    end

  {:error, error} ->
    raise "Ollama request failed: #{inspect(error)}"
end
