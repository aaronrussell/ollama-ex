# Multi-turn Conversation Example
Mix.install([{:ollama, "~> 0.9"}])

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
