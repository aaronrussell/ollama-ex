defmodule Ollama.RequestError do
  @moduledoc """
  Exception raised for pre-request validation errors.

  This error is raised before any HTTP request is made when:
  - Required parameters are missing
  - Parameters have invalid types
  - Parameters have invalid values
  - Configuration is invalid

  ## Fields

    * `message` - Human-readable error description
    * `field` - The field that caused the error (if applicable)
    * `reason` - Structured reason for the error
  """

  defexception [:message, :field, :reason]

  @type t :: %__MODULE__{
          message: String.t(),
          field: atom() | nil,
          reason: atom() | tuple()
        }

  @impl true
  def exception(opts) when is_list(opts) do
    message = Keyword.get(opts, :message, "Request validation failed")
    field = Keyword.get(opts, :field)
    reason = Keyword.get(opts, :reason, :validation_error)

    %__MODULE__{
      message: message,
      field: field,
      reason: reason
    }
  end

  def exception(message) when is_binary(message) do
    %__MODULE__{message: message, field: nil, reason: :validation_error}
  end

  @impl true
  def message(%__MODULE__{message: msg, field: nil}), do: msg
  def message(%__MODULE__{message: msg, field: field}), do: "#{field}: #{msg}"

  @doc """
  Create a missing field error.
  """
  @spec missing_field(atom()) :: t()
  def missing_field(field) do
    exception(
      message: "Required field is missing",
      field: field,
      reason: :missing_required
    )
  end

  @doc """
  Create an invalid type error.
  """
  @spec invalid_type(atom(), any(), String.t()) :: t()
  def invalid_type(field, value, expected) do
    exception(
      message: "Expected #{expected}, got #{inspect(value)}",
      field: field,
      reason: {:invalid_type, expected}
    )
  end

  @doc """
  Create an invalid value error.
  """
  @spec invalid_value(atom(), any(), String.t()) :: t()
  def invalid_value(field, value, constraint) do
    exception(
      message: "Value #{inspect(value)} #{constraint}",
      field: field,
      reason: {:invalid_value, constraint}
    )
  end
end
