defmodule Ollama.Types.ModelInfo do
  @moduledoc """
  Model information.
  """

  use Ollama.Types.Base

  alias Ollama.Types.ModelDetails

  @type t :: %__MODULE__{
          name: String.t() | nil,
          model: String.t() | nil,
          modified_at: String.t() | nil,
          digest: String.t() | nil,
          size: integer() | nil,
          size_vram: integer() | nil,
          expires_at: String.t() | nil,
          context_length: integer() | nil,
          details: ModelDetails.t() | nil
        }

  defstruct [
    :name,
    :model,
    :modified_at,
    :digest,
    :size,
    :size_vram,
    :expires_at,
    :context_length,
    :details
  ]

  def from_map(map) do
    %__MODULE__{
      name: map["name"],
      model: map["model"],
      modified_at: map["modified_at"],
      digest: map["digest"],
      size: map["size"],
      size_vram: map["size_vram"],
      expires_at: map["expires_at"],
      context_length: map["context_length"],
      details: ModelDetails.from_map(map["details"])
    }
  end

  @doc """
  Format size as human-readable string.
  """
  def format_size(%__MODULE__{size: size}) when is_integer(size) do
    cond do
      size >= 1_000_000_000 -> "#{Float.round(size / 1_000_000_000, 1)} GB"
      size >= 1_000_000 -> "#{Float.round(size / 1_000_000, 1)} MB"
      true -> "#{size} bytes"
    end
  end

  def format_size(_), do: "unknown"
end
