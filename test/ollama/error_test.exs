defmodule Ollama.ErrorTest do
  use Supertester.ExUnitFoundation, isolation: :full_isolation, async: false

  alias Ollama.ResponseError

  setup_all do
    {:ok, client: Ollama.init("http://localhost:4000")}
  end

  describe "HTTP error handling" do
    test "returns ResponseError for 404", %{client: client} do
      assert {:error, %ResponseError{status: 404}} =
               Ollama.chat(client,
                 model: "not-found",
                 messages: [%{role: "user", content: "Hello"}]
               )
    end

    test "returns ResponseError for model not found in show", %{client: client} do
      assert {:error, %ResponseError{status: 404}} = Ollama.show_model(client, name: "not-found")
    end

    test "returns ResponseError for model not found in completion", %{client: client} do
      assert {:error, %ResponseError{status: 404}} =
               Ollama.completion(client,
                 model: "not-found",
                 prompt: "Hello"
               )
    end

    test "returns ResponseError for model not found in embed", %{client: client} do
      assert {:error, %ResponseError{status: 404}} =
               Ollama.embed(client,
                 model: "not-found",
                 input: "Hello"
               )
    end
  end

  describe "ResponseError struct" do
    test "has status and message fields" do
      error = %ResponseError{status: 500, message: "Internal error"}
      assert error.status == 500
      assert error.message == "Internal error"
    end

    test "implements Exception behaviour" do
      error = ResponseError.exception(status: 404, body: %{"error" => "Not found"})
      assert Exception.message(error) == "HTTP 404: Not found"
    end
  end
end
