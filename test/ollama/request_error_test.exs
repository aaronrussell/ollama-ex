defmodule Ollama.RequestErrorTest do
  use Supertester.ExUnitFoundation, isolation: :basic

  alias Ollama.RequestError

  describe "exception/1" do
    test "builds from message" do
      error = RequestError.exception("Invalid request")
      assert error.message == "Invalid request"
      assert error.field == nil
      assert error.reason == :validation_error
      assert Exception.message(error) == "Invalid request"
    end

    test "builds from keyword opts" do
      error =
        RequestError.exception(message: "Missing model", field: :model, reason: :missing_required)

      assert error.message == "Missing model"
      assert error.field == :model
      assert error.reason == :missing_required
      assert Exception.message(error) == "model: Missing model"
    end
  end

  describe "helpers" do
    test "missing_field/1" do
      error = RequestError.missing_field(:messages)
      assert error.field == :messages
      assert error.reason == :missing_required
      assert Exception.message(error) == "messages: Required field is missing"
    end

    test "invalid_type/3" do
      error = RequestError.invalid_type(:stream, "yes", "boolean")
      assert error.field == :stream
      assert error.reason == {:invalid_type, "boolean"}
      assert String.contains?(Exception.message(error), "Expected boolean")
    end

    test "invalid_value/3" do
      error = RequestError.invalid_value(:top_p, 2.0, "must be <= 1.0")
      assert error.field == :top_p
      assert error.reason == {:invalid_value, "must be <= 1.0"}
      assert String.contains?(Exception.message(error), "must be <= 1.0")
    end
  end
end
