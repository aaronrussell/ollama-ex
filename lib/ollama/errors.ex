defmodule Ollama.Errors do
  @moduledoc """
  Error handling utilities for Ollama.

  ## Error Types

    * `Ollama.RequestError` - Pre-request validation errors
    * `Ollama.ResponseError` - API response errors
  """

  alias Ollama.{RequestError, ResponseError}

  @doc """
  Wrap a function result, converting errors to appropriate types.
  """
  @spec wrap(term()) :: {:ok, term()} | {:error, RequestError.t() | ResponseError.t()}
  def wrap({:ok, _} = success), do: success
  def wrap({:error, %RequestError{}} = error), do: error
  def wrap({:error, %ResponseError{}} = error), do: error

  def wrap({:error, %{status: _status} = response}),
    do: {:error, ResponseError.from_response(response)}

  def wrap({:error, reason}), do: {:error, RequestError.exception(inspect(reason))}

  @doc """
  Check if an error is retryable.
  """
  @spec retryable?(RequestError.t() | ResponseError.t()) :: boolean()
  def retryable?(%ResponseError{} = e), do: ResponseError.retryable?(e)
  def retryable?(%RequestError{}), do: false

  @doc """
  Get error message from any error type.
  """
  @spec error_message(RequestError.t() | ResponseError.t() | term()) :: String.t()
  def error_message(%RequestError{} = e), do: Exception.message(e)
  def error_message(%ResponseError{} = e), do: Exception.message(e)
  def error_message(other), do: inspect(other)

  @doc """
  Format error for logging.
  """
  @spec format_for_log(RequestError.t() | ResponseError.t()) :: String.t()
  def format_for_log(%RequestError{} = e) do
    "[Ollama.RequestError] #{Exception.message(e)}"
  end

  def format_for_log(%ResponseError{status: status} = e) do
    "[Ollama.ResponseError] HTTP #{status}: #{e.error || e.message}"
  end
end
