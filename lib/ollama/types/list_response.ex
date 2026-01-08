defmodule Ollama.Types.ListResponse do
  @moduledoc """
  Response from list_models.
  """

  use Ollama.Types.Base

  alias Ollama.Types.ModelInfo

  @type t :: %__MODULE__{models: [ModelInfo.t()]}
  defstruct models: []

  def from_map(%{"models" => models}) when is_list(models) do
    %__MODULE__{models: Enum.map(models, &ModelInfo.from_map/1)}
  end

  def from_map(_), do: %__MODULE__{}

  @doc """
  Get model names.
  """
  def names(%__MODULE__{models: models}), do: Enum.map(models, & &1.name)

  @doc """
  Find model by name.
  """
  def find(%__MODULE__{models: models}, name) do
    Enum.find(models, &(&1.name == name))
  end
end
