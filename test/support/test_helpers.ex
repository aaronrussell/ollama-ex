defmodule Ollama.TestHelpers do
  @moduledoc "Test helper functions"

  @doc "Starts the mock server unless it is already running."
  def start_mock_server(port \\ 4000) do
    case Bandit.start_link(plug: Ollama.MockServer, port: port) do
      {:ok, pid} ->
        {:ok, pid, :started}

      {:error, {:already_started, pid}} ->
        {:ok, pid, :already_started}

      {:error, {:shutdown, {:failed_to_start_child, :listener, :eaddrinuse}}} ->
        {:ok, nil, :already_started}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc "Creates a user message map"
  def user_message(content), do: %{role: "user", content: content}

  @doc "Creates a system message map"
  def system_message(content), do: %{role: "system", content: content}

  @doc "Creates an assistant message map"
  def assistant_message(content), do: %{role: "assistant", content: content}

  @doc "Collects all stream chunks into a list"
  def collect_stream(stream) do
    stream |> Enum.to_list()
  end

  @doc "Extracts content from chat stream chunks"
  def extract_chat_content(chunks) do
    chunks
    |> Enum.map(&get_in(&1, ["message", "content"]))
    |> Enum.reject(&is_nil/1)
    |> Enum.join("")
  end
end
