# Basic Completion Example
Mix.install([{:ollama, "~> 0.9"}])

client = Ollama.init()

{:ok, response} =
  Ollama.completion(client,
    model: "llama3.2",
    prompt: "The capital of France is"
  )

IO.puts(response["response"])
