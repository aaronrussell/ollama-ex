# Thinking Mode Streaming Example
# Run with: elixir examples/thinking/thinking_stream.exs

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

model = "deepseek-r1:1.5b"
expected = "1, 2, 3, 4, 5"

build_messages = fn stricter? ->
  system =
    if stricter? do
      "Put all reasoning in thinking. Respond with exactly: 1, 2, 3, 4, 5. " <>
        "No other words, digits, punctuation, or newlines."
    else
      "Put reasoning in thinking. Respond with exactly: 1, 2, 3, 4, 5."
    end

  [
    %{role: "system", content: system},
    %{role: "user", content: "Count from 1 to 5."}
  ]
end

normalize_sequence = fn content ->
  trimmed = String.trim(content)

  cond do
    trimmed == expected ->
      {:ok, expected}

    String.replace(trimmed, ~r/[^0-9]/, "") == "12345" ->
      {:ok, expected}

    true ->
      :error
  end
end

run_stream = fn stream ->
  Enum.reduce(stream, "", fn chunk, acc ->
    if thinking = get_in(chunk, ["message", "thinking"]) do
      IO.write(thinking)
    end

    content = get_in(chunk, ["message", "content"]) || ""
    acc <> content
  end)
end

run_once = fn messages ->
  stream_result =
    Ollama.chat(client,
      model: model,
      messages: messages,
      think: true,
      stream: true,
      options: [temperature: 0]
    )

  case stream_result do
    {:ok, stream} ->
      try do
        content = run_stream.(stream)
        IO.puts("")
        {:ok, content}
      rescue
        error in Ollama.ResponseError ->
          if error.status == 400 do
            IO.puts(
              "Thinking not supported by #{model}; streaming without think. " <>
                "Use a model that supports `think` to see thinking output."
            )

            {:ok, fallback_stream} =
              Ollama.chat(client,
                model: model,
                messages: messages,
                stream: true,
                options: [temperature: 0]
              )

            content = run_stream.(fallback_stream)
            IO.puts("")
            {:ok, content}
          else
            reraise error, __STACKTRACE__
          end
      end

    {:error, error} ->
      {:error, error}
  end
end

with {:ok, content} <- run_once.(build_messages.(false)),
     {:ok, final} <- normalize_sequence.(content) do
  IO.puts(final)
else
  {:error, error} ->
    raise "Ollama request failed: #{inspect(error)}"

  :error ->
    {:ok, retry_content} = run_once.(build_messages.(true))

    case normalize_sequence.(retry_content) do
      {:ok, final} ->
        IO.puts(final)

      :error ->
        IO.puts(String.trim(retry_content))
    end
end
