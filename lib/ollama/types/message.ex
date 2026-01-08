defmodule Ollama.Types.Message do
  @moduledoc """
  Chat message structure.
  """

  use Ollama.Types.Base

  alias Ollama.Types.ToolCall

  @type t :: %__MODULE__{
          role: String.t() | nil,
          content: String.t() | nil,
          thinking: String.t() | nil,
          images: [String.t()] | nil,
          tool_name: String.t() | nil,
          tool_calls: [ToolCall.t()] | nil
        }

  defstruct [:role, :content, :thinking, :images, :tool_name, :tool_calls]

  @spec from_map(map()) :: t()
  def from_map(map) when is_map(map) do
    %__MODULE__{
      role: map["role"],
      content: map["content"],
      thinking: map["thinking"],
      images: map["images"],
      tool_name: map["tool_name"] || map["toolname"],
      tool_calls: parse_tool_calls(map["tool_calls"])
    }
  end

  defp parse_tool_calls(nil), do: nil

  defp parse_tool_calls(calls) when is_list(calls) do
    Enum.map(calls, &ToolCall.from_map/1)
  end

  defp parse_tool_calls(_), do: nil
end
