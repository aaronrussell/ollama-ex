defmodule Ollama.Types.EmbedResponse do
  @moduledoc """
  Response from embed endpoint.
  """

  use Ollama.Types.Base

  @type t :: %__MODULE__{
          model: String.t() | nil,
          embeddings: [[float()]],
          total_duration: integer() | nil,
          load_duration: integer() | nil,
          prompt_eval_count: integer() | nil
        }

  defstruct [:model, :total_duration, :load_duration, :prompt_eval_count, embeddings: []]

  @spec from_map(map()) :: t()
  def from_map(map) when is_map(map) do
    %__MODULE__{
      model: map["model"],
      embeddings: map["embeddings"] || [],
      total_duration: map["total_duration"],
      load_duration: map["load_duration"],
      prompt_eval_count: map["prompt_eval_count"]
    }
  end

  @doc """
  Get the first (or only) embedding.
  """
  @spec first(t()) :: [float()] | nil
  def first(%__MODULE__{embeddings: [first | _]}), do: first
  def first(_), do: nil

  @doc """
  Get embedding dimensions.
  """
  @spec dimensions(t()) :: integer()
  def dimensions(%__MODULE__{embeddings: [first | _]}), do: length(first)
  def dimensions(_), do: 0
end
