defmodule Ollama.Types.StatusResponse do
  @moduledoc """
  Simple status response.
  """

  use Ollama.Types.Base

  @type t :: %__MODULE__{status: String.t() | nil}
  defstruct [:status]

  def from_map(map), do: %__MODULE__{status: map["status"]}

  def success?(%__MODULE__{status: "success"}), do: true
  def success?(_), do: false
end
