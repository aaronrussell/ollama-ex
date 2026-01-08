defmodule Ollama.Web.SearchResult do
  @moduledoc """
  Single web search result.
  """

  use Ollama.Types.Base

  @type t :: %__MODULE__{
          title: String.t() | nil,
          url: String.t() | nil,
          content: String.t() | nil
        }

  defstruct [:title, :url, :content]

  def from_map(map) do
    %__MODULE__{
      title: map["title"],
      url: map["url"],
      content: map["content"]
    }
  end
end
