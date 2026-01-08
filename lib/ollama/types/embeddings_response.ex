defmodule Ollama.Types.EmbeddingsResponse do
  @moduledoc """
  Response from embeddings endpoint.
  """

  use Ollama.Types.Base

  @type t :: %__MODULE__{
          embedding: [float()]
        }

  defstruct embedding: []

  @spec from_map(map()) :: t()
  def from_map(map) when is_map(map) do
    %__MODULE__{
      embedding: map["embedding"] || []
    }
  end

  @doc """
  Get embedding dimensions.
  """
  @spec dimensions(t()) :: integer()
  def dimensions(%__MODULE__{embedding: embedding}) when is_list(embedding), do: length(embedding)
  def dimensions(_), do: 0
end
