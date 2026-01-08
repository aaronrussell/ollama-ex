# Chat Logprobs Example
# Run with: elixir examples/advanced/chat_logprobs.exs

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
model = System.get_env("OLLAMA_LOGPROBS_MODEL", "llama3.2")

print_logprobs = fn logprobs, label ->
  IO.puts("\n#{label}:")

  Enum.each(logprobs, fn entry ->
    token = Map.get(entry, "token")
    logprob = Map.get(entry, "logprob", 0.0)
    IO.puts("  token=#{inspect(token)} logprob=#{Float.round(logprob, 3)}")

    Enum.each(Map.get(entry, "top_logprobs", []), fn alt ->
      if Map.get(alt, "token") != token do
        alt_logprob = Map.get(alt, "logprob", 0.0)
        IO.puts("    alt -> #{inspect(alt["token"])} (#{Float.round(alt_logprob, 3)})")
      end
    end)
  end)
end

messages = [
  %{role: "user", content: "hi! be concise."}
]

{:ok, response} =
  Ollama.chat(client,
    model: model,
    messages: messages,
    logprobs: true,
    top_logprobs: 3
  )

IO.puts("Chat response: #{get_in(response, ["message", "content"])}")
print_logprobs.(Map.get(response, "logprobs", []), "chat logprobs")
