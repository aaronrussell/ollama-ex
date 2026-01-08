defmodule Ollama.Web do
  @moduledoc """
  Web search and fetch functionality for Ollama cloud API.

  These functions require an Ollama API key when calling the hosted API.
  Set the `OLLAMA_API_KEY` environment variable or pass authorization headers
  when initializing the client.
  """

  alias Ollama.{RequestError, ResponseError}
  alias Ollama.Web.{FetchResponse, SearchResponse}

  @cloud_base_url "https://ollama.com/api"

  @type search_opts :: [
          query: String.t(),
          max_results: pos_integer(),
          base_url: String.t()
        ]

  @type fetch_opts :: [
          url: String.t(),
          base_url: String.t()
        ]

  @doc """
  Search the web using Ollama's cloud search API.
  """
  @spec search(Ollama.client(), search_opts()) :: {:ok, SearchResponse.t()} | {:error, term()}
  def search(%Ollama{} = client, opts) do
    {base_url, opts} = pop_base_url(opts)

    with {:ok, validated} <- validate_search_opts(opts),
         {:ok, cloud_client} <- ensure_cloud_client(client, base_url),
         {:ok, response} <- do_request(cloud_client, :post, "/web_search", validated) do
      {:ok, SearchResponse.from_map(response)}
    end
  end

  @doc """
  Search the web, raising on error.
  """
  @spec search!(Ollama.client(), search_opts()) :: SearchResponse.t()
  def search!(client, opts) do
    case search(client, opts) do
      {:ok, response} -> response
      {:error, reason} -> raise "Web search failed: #{inspect(reason)}"
    end
  end

  @doc """
  Fetch and extract content from a URL.
  """
  @spec fetch(Ollama.client(), fetch_opts()) :: {:ok, FetchResponse.t()} | {:error, term()}
  def fetch(%Ollama{} = client, opts) do
    {base_url, opts} = pop_base_url(opts)

    with {:ok, validated} <- validate_fetch_opts(opts),
         {:ok, cloud_client} <- ensure_cloud_client(client, base_url),
         {:ok, response} <- do_request(cloud_client, :post, "/web_fetch", validated) do
      {:ok, FetchResponse.from_map(response)}
    end
  end

  @doc """
  Fetch content, raising on error.
  """
  @spec fetch!(Ollama.client(), fetch_opts()) :: FetchResponse.t()
  def fetch!(client, opts) do
    case fetch(client, opts) do
      {:ok, response} -> response
      {:error, reason} -> raise "Web fetch failed: #{inspect(reason)}"
    end
  end

  defp validate_search_opts(opts) do
    query = Keyword.get(opts, :query)
    max_results = Keyword.get(opts, :max_results, 3)

    cond do
      is_nil(query) or query == "" ->
        {:error, RequestError.missing_field(:query)}

      not is_binary(query) ->
        {:error, RequestError.invalid_type(:query, query, "string")}

      not is_integer(max_results) or max_results < 1 ->
        {:error,
         RequestError.invalid_value(:max_results, max_results, "must be positive integer")}

      true ->
        {:ok, %{query: query, max_results: max_results}}
    end
  end

  defp validate_fetch_opts(opts) do
    url = Keyword.get(opts, :url)

    cond do
      is_nil(url) or url == "" ->
        {:error, RequestError.missing_field(:url)}

      not is_binary(url) ->
        {:error, RequestError.invalid_type(:url, url, "string")}

      true ->
        {:ok, %{url: url}}
    end
  end

  defp ensure_cloud_client(%Ollama{req: req}, base_url) do
    base_url = normalize_base_url(base_url || default_base_url())

    req = Req.Request.put_option(req, :base_url, base_url)

    with {:ok, req} <- ensure_auth(req, base_url) do
      {:ok, %Ollama{req: req}}
    end
  end

  defp ensure_auth(req, base_url) do
    if cloud_host?(base_url) do
      case Req.Request.get_header(req, "authorization") do
        [] ->
          case System.get_env("OLLAMA_API_KEY") do
            nil ->
              {:error,
               RequestError.exception(
                 message: "OLLAMA_API_KEY is required for web endpoints",
                 reason: :missing_api_key
               )}

            "" ->
              {:error,
               RequestError.exception(
                 message: "OLLAMA_API_KEY is required for web endpoints",
                 reason: :missing_api_key
               )}

            key ->
              {:ok, Req.Request.put_header(req, "authorization", "Bearer #{key}")}
          end

        values ->
          if Enum.any?(values, &String.starts_with?(&1, "Bearer ")) do
            {:ok, req}
          else
            {:error,
             RequestError.exception(
               message: "Authorization header with Bearer token is required for web endpoints",
               reason: :invalid_api_key
             )}
          end
      end
    else
      {:ok, req}
    end
  end

  defp cloud_host?(base_url) do
    case URI.parse(base_url) do
      %URI{host: host} when is_binary(host) -> String.contains?(host, "ollama.com")
      _ -> false
    end
  end

  defp do_request(%Ollama{req: req}, method, url, body) do
    req
    |> Req.request(method: method, url: normalize_url(url), json: body)
    |> handle_response()
  end

  defp handle_response({:ok, %{status: status, body: body}}) when status in 200..299 do
    {:ok, body}
  end

  defp handle_response({:ok, %{status: status, body: body}}) do
    {:error, ResponseError.exception(status: status, body: body)}
  end

  defp handle_response({:error, %Req.TransportError{reason: reason}}) do
    {:error,
     RequestError.exception(
       message: "Connection failed: #{inspect(reason)}",
       reason: :connection_error
     )}
  end

  defp handle_response({:error, reason}) do
    {:error, RequestError.exception(inspect(reason))}
  end

  defp pop_base_url(opts) do
    {Keyword.get(opts, :base_url), Keyword.delete(opts, :base_url)}
  end

  defp normalize_url(url) when is_binary(url), do: String.trim_leading(url, "/")

  defp normalize_base_url(url) do
    trimmed = String.trim_trailing(url, "/")

    if String.ends_with?(trimmed, "/api") do
      trimmed
    else
      trimmed <> "/api"
    end
  end

  defp default_base_url do
    System.get_env("OLLAMA_WEB_BASE_URL") || Application.get_env(:ollama, :web_base_url) ||
      @cloud_base_url
  end
end
