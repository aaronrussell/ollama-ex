defmodule Ollama.ErrorTest do
  use ExUnit.Case, async: true
  alias Ollama.HTTPError

  setup_all do
    {:ok, pid} = Bandit.start_link(plug: Ollama.MockServer)
    on_exit(fn -> Process.exit(pid, :normal) end)
    {:ok, client: Ollama.init("http://localhost:4000")}
  end

  describe "HTTP error handling" do
    test "returns HTTPError for 404", %{client: client} do
      assert {:error, %HTTPError{status: 404}} =
               Ollama.chat(client,
                 model: "not-found",
                 messages: [%{role: "user", content: "Hello"}]
               )
    end

    test "returns HTTPError for model not found in show", %{client: client} do
      assert {:error, %HTTPError{status: 404}} = Ollama.show_model(client, name: "not-found")
    end

    test "returns HTTPError for model not found in completion", %{client: client} do
      assert {:error, %HTTPError{status: 404}} =
               Ollama.completion(client,
                 model: "not-found",
                 prompt: "Hello"
               )
    end

    test "returns HTTPError for model not found in embed", %{client: client} do
      assert {:error, %HTTPError{status: 404}} =
               Ollama.embed(client,
                 model: "not-found",
                 input: "Hello"
               )
    end
  end

  describe "HTTPError struct" do
    test "has status and message fields" do
      error = %HTTPError{status: 500, message: "Internal error"}
      assert error.status == 500
      assert error.message == "Internal error"
    end

    test "implements Exception behaviour" do
      error = %HTTPError{status: 404, message: "Not found"}
      assert Exception.message(error) == "HTTP 404: Not found"
    end
  end
end
