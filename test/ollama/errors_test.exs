defmodule Ollama.ErrorsTest do
  use Supertester.ExUnitFoundation, isolation: :basic

  alias Ollama.{Errors, RequestError, ResponseError}

  describe "wrap/1" do
    test "passes through ok tuple" do
      assert {:ok, :value} = Errors.wrap({:ok, :value})
    end

    test "passes through RequestError" do
      error = RequestError.exception("oops")
      assert {:error, ^error} = Errors.wrap({:error, error})
    end

    test "converts response-like errors" do
      response = %{status: 500, body: %{"error" => "server"}}

      assert {:error, %ResponseError{status: 500, error: "server"}} =
               Errors.wrap({:error, response})
    end

    test "wraps other errors as RequestError" do
      assert {:error, %RequestError{}} = Errors.wrap({:error, :bad_request})
    end
  end

  describe "retryable?/1" do
    test "uses ResponseError retryable" do
      assert Errors.retryable?(ResponseError.exception(503))
      refute Errors.retryable?(ResponseError.exception(400))
    end

    test "returns false for RequestError" do
      refute Errors.retryable?(RequestError.exception("nope"))
    end
  end

  describe "error_message/1" do
    test "formats known errors" do
      error = RequestError.exception("bad")
      assert Errors.error_message(error) == "bad"
    end
  end

  describe "format_for_log/1" do
    test "formats RequestError" do
      error = RequestError.exception("bad")
      assert Errors.format_for_log(error) == "[Ollama.RequestError] bad"
    end

    test "formats ResponseError" do
      error = ResponseError.exception(status: 500, body: %{"error" => "boom"})
      assert Errors.format_for_log(error) == "[Ollama.ResponseError] HTTP 500: boom"
    end
  end
end
