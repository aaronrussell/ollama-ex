defmodule Ollama.ResponseErrorTest do
  use ExUnit.Case, async: true

  alias Ollama.ResponseError

  describe "exception/1" do
    test "builds from status" do
      error = ResponseError.exception(404)
      assert error.status == 404
      assert error.message != nil
      assert String.contains?(Exception.message(error), "HTTP 404")
    end

    test "extracts error from map body" do
      error = ResponseError.exception(status: 400, body: %{"error" => "Model not found"})
      assert error.error == "Model not found"
      assert error.message == "Model not found"
    end

    test "extracts error from JSON string body" do
      error = ResponseError.exception(status: 400, body: ~s({"error": "Invalid model"}))
      assert error.error == "Invalid model"
      assert error.message == "Invalid model"
    end

    test "uses raw string body when not JSON" do
      error = ResponseError.exception(status: 400, body: "Bad request")
      assert error.error == "Bad request"
      assert error.message == "Bad request"
    end
  end

  describe "helpers" do
    test "client_error?/1" do
      assert ResponseError.client_error?(ResponseError.exception(400))
      refute ResponseError.client_error?(ResponseError.exception(500))
    end

    test "server_error?/1" do
      assert ResponseError.server_error?(ResponseError.exception(500))
      refute ResponseError.server_error?(ResponseError.exception(404))
    end

    test "not_found?/1" do
      assert ResponseError.not_found?(ResponseError.exception(404))
      refute ResponseError.not_found?(ResponseError.exception(400))
    end

    test "unauthorized?/1" do
      assert ResponseError.unauthorized?(ResponseError.exception(401))
      assert ResponseError.unauthorized?(ResponseError.exception(403))
      refute ResponseError.unauthorized?(ResponseError.exception(404))
    end

    test "retryable?/1" do
      assert ResponseError.retryable?(ResponseError.exception(500))
      assert ResponseError.retryable?(ResponseError.exception(503))
      refute ResponseError.retryable?(ResponseError.exception(400))
    end
  end
end
