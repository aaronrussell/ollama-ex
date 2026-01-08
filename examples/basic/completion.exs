# Basic Completion Example
root = Path.expand("../..", __DIR__)

ollama_dep =
  if File.exists?(Path.join(root, "mix.exs")) do
    {:ollama, path: root}
  else
    {:ollama, "~> 0.10.0"}
  end

Mix.install([ollama_dep])

client = Ollama.init()

{:ok, response} =
  Ollama.completion(client,
    model: "llama3.2",
    prompt: "The capital of France is"
  )

IO.puts(response["response"])
