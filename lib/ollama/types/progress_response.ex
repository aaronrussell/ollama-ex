defmodule Ollama.Types.ProgressResponse do
  @moduledoc """
  Progress response for pull/push/create operations.
  """

  use Ollama.Types.Base

  @type t :: %__MODULE__{
          status: String.t() | nil,
          digest: String.t() | nil,
          completed: integer() | nil,
          total: integer() | nil
        }

  defstruct [:status, :digest, :completed, :total]

  def from_map(map) do
    %__MODULE__{
      status: map["status"],
      digest: map["digest"],
      completed: map["completed"],
      total: map["total"]
    }
  end

  @doc """
  Calculate progress percentage.
  """
  def percent(%__MODULE__{completed: c, total: t})
      when is_integer(c) and is_integer(t) and t > 0 do
    Float.round(c / t * 100, 1)
  end

  def percent(_), do: 0.0

  @doc """
  Check if operation is complete.
  """
  def complete?(%__MODULE__{completed: c, total: t}) when c == t, do: true
  def complete?(%__MODULE__{status: "success"}), do: true
  def complete?(_), do: false
end
