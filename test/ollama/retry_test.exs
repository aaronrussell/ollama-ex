defmodule Ollama.RetryTest do
  use ExUnit.Case, async: true

  alias Ollama.{Retry, ResponseError}

  test "retries until success" do
    counter = :counters.new(1, [])

    fun = fn ->
      attempt = :counters.add(counter, 1, 1)

      if attempt < 3 do
        {:error, ResponseError.exception(503)}
      else
        {:ok, :done}
      end
    end

    assert {:ok, :done} = Retry.with_backoff(fun, max_attempts: 3, base_delay: 1, max_delay: 1)
  end

  test "returns last failure when max attempts reached" do
    fun = fn -> {:error, ResponseError.exception(503)} end

    assert {:error, %ResponseError{status: 503}} =
             Retry.with_backoff(fun, max_attempts: 2, base_delay: 1, max_delay: 1)
  end
end
