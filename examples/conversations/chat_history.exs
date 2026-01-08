# Multi-turn Conversation Example
root = Path.expand("../..", __DIR__)

ollama_dep =
  if File.exists?(Path.join(root, "mix.exs")) do
    {:ollama, path: root}
  else
    {:ollama, "~> 0.10.0"}
  end

Mix.install([ollama_dep])

defmodule Conversation do
  def run do
    client = Ollama.init()
    loop(client, [])
  end

  defp loop(client, messages) do
    IO.write("You: ")
    input = IO.gets("") |> String.trim()

    if input == "quit" do
      IO.puts("Goodbye!")
    else
      messages = messages ++ [%{role: "user", content: input}]

      {:ok, response} =
        Ollama.chat(client,
          model: "llama3.2",
          messages: messages
        )

      assistant_content = response["message"]["content"]
      IO.puts("\nAssistant: #{assistant_content}\n")

      messages = messages ++ [%{role: "assistant", content: assistant_content}]
      loop(client, messages)
    end
  end
end

Conversation.run()
