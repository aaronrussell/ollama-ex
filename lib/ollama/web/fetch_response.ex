defmodule Ollama.Web.FetchResponse do
  @moduledoc """
  Response from web_fetch.
  """

  use Ollama.Types.Base

  @type t :: %__MODULE__{
          title: String.t() | nil,
          content: String.t() | nil,
          links: [String.t()] | nil
        }

  defstruct [:title, :content, :links]

  def from_map(map) do
    %__MODULE__{
      title: map["title"],
      content: map["content"],
      links: map["links"]
    }
  end
end
