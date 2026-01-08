defmodule Ollama.Types.ProcessResponse do
  @moduledoc """
  Response from list_running (ps).
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
  Total VRAM usage.
  """
  def total_vram(%__MODULE__{models: models}) do
    models
    |> Enum.map(&(&1.size_vram || 0))
    |> Enum.sum()
  end
end
