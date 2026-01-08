defmodule Ollama.ResponseError do
  @moduledoc """
  Exception raised for API response errors.

  This error is raised when the Ollama API returns an error response.
  It includes both the HTTP status code and the API error message.
  """

  defexception [:status, :message, :error, :body]

  @type t :: %__MODULE__{
          status: integer(),
          message: String.t(),
          error: String.t() | nil,
          body: map() | String.t() | nil
        }

  @impl true
  def exception(opts) when is_list(opts) do
    status = Keyword.fetch!(opts, :status)
    body = Keyword.get(opts, :body)
    error = extract_error(body)

    message = error || Keyword.get(opts, :message) || status_message(status)

    %__MODULE__{
      status: status,
      message: message,
      error: error,
      body: body
    }
  end

  def exception(status) when is_integer(status) do
    exception(status: status, message: status_message(status))
  end

  @impl true
  def message(%__MODULE__{status: status, message: msg}) do
    "HTTP #{status}: #{msg}"
  end

  @doc """
  Create from HTTP response.
  """
  @spec from_response(Req.Response.t() | map()) :: t()
  def from_response(%{status: status, body: body}) do
    exception(status: status, body: body)
  end

  @doc """
  Check if error is a client error (4xx).
  """
  @spec client_error?(t()) :: boolean()
  def client_error?(%__MODULE__{status: status}), do: status >= 400 and status < 500

  @doc """
  Check if error is a server error (5xx).
  """
  @spec server_error?(t()) :: boolean()
  def server_error?(%__MODULE__{status: status}), do: status >= 500

  @doc """
  Check if error indicates model not found.
  """
  @spec not_found?(t()) :: boolean()
  def not_found?(%__MODULE__{status: 404}), do: true
  def not_found?(_), do: false

  @doc """
  Check if error indicates unauthorized.
  """
  @spec unauthorized?(t()) :: boolean()
  def unauthorized?(%__MODULE__{status: status}) when status in [401, 403], do: true
  def unauthorized?(_), do: false

  @doc """
  Check if error is retryable.
  """
  @spec retryable?(t()) :: boolean()
  def retryable?(%__MODULE__{status: status}) when status in [429, 500, 502, 503, 504], do: true
  def retryable?(_), do: false

  defp extract_error(body) when is_map(body) do
    body["error"] || body[:error]
  end

  defp extract_error(body) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, %{"error" => error}} -> error
      {:ok, %{"message" => message}} -> message
      _ -> body
    end
  end

  defp extract_error(_), do: nil

  defp status_message(status) do
    Plug.Conn.Status.reason_phrase(status)
  rescue
    _ -> "Unknown error"
  end
end
