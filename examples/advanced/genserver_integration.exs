# GenServer Chat Wrapper
root = Path.expand("../..", __DIR__)

ollama_dep =
  if File.exists?(Path.join(root, "mix.exs")) do
    {:ollama, path: root}
  else
    {:ollama, "~> 0.10.0"}
  end

Mix.install([ollama_dep])

defmodule ChatServer do
  use GenServer

  def start_link(opts \\ []) do
    model = Keyword.get(opts, :model, "llama3.2")
    GenServer.start_link(__MODULE__, model, name: __MODULE__)
  end

  def chat(message), do: GenServer.call(__MODULE__, {:chat, message}, 60_000)
  def reset(), do: GenServer.cast(__MODULE__, :reset)
  def history(), do: GenServer.call(__MODULE__, :history)

  @impl true
  def init(model) do
    {:ok, %{client: Ollama.init(), model: model, messages: []}}
  end

  @impl true
  def handle_call({:chat, content}, _from, state) do
    messages = state.messages ++ [%{role: "user", content: content}]

    case Ollama.chat(state.client, model: state.model, messages: messages) do
      {:ok, response} ->
        assistant_msg = response["message"]
        messages = messages ++ [%{role: "assistant", content: assistant_msg["content"]}]
        {:reply, {:ok, assistant_msg["content"]}, %{state | messages: messages}}

      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  @impl true
  def handle_call(:history, _from, state) do
    {:reply, state.messages, state}
  end

  @impl true
  def handle_cast(:reset, state) do
    {:noreply, %{state | messages: []}}
  end
end

# Usage
{:ok, _} = ChatServer.start_link(model: "llama3.2")

{:ok, response} = ChatServer.chat("Hello! What's your name?")
IO.puts("Assistant: #{response}")

{:ok, response} = ChatServer.chat("What did I just ask you?")
IO.puts("Assistant: #{response}")

IO.inspect(ChatServer.history(), label: "Conversation History")
