defmodule Ollama.ConnectionError do
  @moduledoc """
  Exception raised when unable to connect to the Ollama server.

  The message includes a reminder to start Ollama and a download link.
  """

  defexception [:message, :original_error, :reason]

  @type t :: %__MODULE__{
          message: String.t(),
          original_error: term(),
          reason: term()
        }

  @base_message "Could not connect to Ollama. Please ensure the server is running. Download at https://ollama.com/download"

  @impl true
  def exception(opts) when is_list(opts) do
    original_error = Keyword.get(opts, :original_error)
    reason = Keyword.get(opts, :reason) || extract_reason(original_error)
    message = Keyword.get(opts, :message) || format_message(reason)

    %__MODULE__{
      message: message,
      original_error: original_error,
      reason: reason
    }
  end

  def exception(original_error) do
    exception(original_error: original_error)
  end

  @impl true
  def message(%__MODULE__{message: msg}), do: msg

  defp format_message(nil), do: @base_message

  defp format_message(reason) do
    "#{@base_message} (reason: #{format_reason(reason)})"
  end

  defp extract_reason(%{reason: reason}), do: reason
  defp extract_reason(_), do: nil

  defp format_reason(reason) when is_binary(reason), do: reason
  defp format_reason(reason), do: inspect(reason)
end
