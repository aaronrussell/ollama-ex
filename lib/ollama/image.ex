defmodule Ollama.Image do
  @moduledoc """
  Image handling utilities for multimodal models.

  Provides automatic loading and Base64 encoding of images from:
  - File paths
  - Binary data
  - Already-encoded Base64 strings
  - URLs (download and encode)
  """

  @supported_extensions ~w(.png .jpg .jpeg .webp .gif)

  @type image_input :: binary() | String.t()
  @type encoded_image :: String.t()

  @doc """
  Encode an image to Base64.
  """
  @spec encode(image_input()) :: {:ok, encoded_image()} | {:error, term()}
  def encode(input) when is_binary(input) do
    cond do
      File.exists?(input) ->
        encode_file(input)

      image_extension?(input) ->
        {:error, {:file_not_found, input}}

      image_binary?(input) ->
        {:ok, Base.encode64(input)}

      valid_base64?(input) ->
        {:ok, input}

      true ->
        {:error, {:invalid_image, "Could not determine image format"}}
    end
  end

  @doc """
  Encode an image, raising on error.
  """
  @spec encode!(image_input()) :: encoded_image()
  def encode!(input) do
    case encode(input) do
      {:ok, encoded} -> encoded
      {:error, reason} -> raise ArgumentError, "Failed to encode image: #{inspect(reason)}"
    end
  end

  @doc """
  Encode multiple images.

  Returns `{:ok, list}` if all succeed, `{:error, reason}` on first failure.
  """
  @spec encode_all([image_input()]) :: {:ok, [encoded_image()]} | {:error, term()}
  def encode_all(inputs) when is_list(inputs) do
    Enum.reduce_while(inputs, {:ok, []}, fn input, {:ok, acc} ->
      case encode(input) do
        {:ok, encoded} -> {:cont, {:ok, acc ++ [encoded]}}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  @doc """
  Encode multiple images, raising on error.
  """
  @spec encode_all!([image_input()]) :: [encoded_image()]
  def encode_all!(inputs) do
    case encode_all(inputs) do
      {:ok, encoded} -> encoded
      {:error, reason} -> raise ArgumentError, "Failed to encode images: #{inspect(reason)}"
    end
  end

  @doc """
  Load and encode an image from a URL.

  ## Options

    * `:timeout` - Request timeout in ms (default: 30_000)
    * `:max_size` - Maximum file size in bytes (default: 20MB)
  """
  @spec from_url(String.t(), keyword()) :: {:ok, encoded_image()} | {:error, term()}
  def from_url(url, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 30_000)
    max_size = Keyword.get(opts, :max_size, 20 * 1024 * 1024)

    case Req.get(url, receive_timeout: timeout) do
      {:ok, %{status: 200, body: body}} when byte_size(body) <= max_size ->
        encode(body)

      {:ok, %{status: 200, body: body}} ->
        {:error, {:file_too_large, byte_size(body), max_size}}

      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, {:download_failed, reason}}
    end
  end

  defp encode_file(path) do
    case File.read(path) do
      {:ok, data} -> {:ok, Base.encode64(data)}
      {:error, reason} -> {:error, {:read_error, path, reason}}
    end
  end

  defp image_extension?(input) do
    ext = Path.extname(input) |> String.downcase()
    ext in @supported_extensions
  end

  defp image_binary?(data) do
    cond do
      not String.valid?(data) ->
        true

      true ->
        magic_bytes?(data)
    end
  end

  defp magic_bytes?(<<0x89, 0x50, 0x4E, 0x47, _::binary>>), do: true
  defp magic_bytes?(<<0xFF, 0xD8, 0xFF, _::binary>>), do: true
  defp magic_bytes?(<<0x47, 0x49, 0x46, _::binary>>), do: true

  defp magic_bytes?(
         <<0x52, 0x49, 0x46, 0x46, _::binary-size(4), 0x57, 0x45, 0x42, 0x50, _::binary>>
       ),
       do: true

  defp magic_bytes?(_), do: false

  defp valid_base64?(input) do
    case Base.decode64(input) do
      {:ok, decoded} when byte_size(decoded) > 0 -> true
      _ -> false
    end
  end
end
