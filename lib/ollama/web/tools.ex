defmodule Ollama.Web.Tools do
  @moduledoc """
  Tool definitions for web search and fetch.
  """

  @spec all() :: [map()]
  def all do
    [search_tool(), fetch_tool()]
  end

  @doc """
  Tool definition for web search.
  """
  @spec search_tool() :: map()
  def search_tool do
    %{
      type: "function",
      function: %{
        name: "web_search",
        description: "Search the web for current information.",
        parameters: %{
          type: "object",
          properties: %{
            query: %{
              type: "string",
              description: "The search query"
            },
            max_results: %{
              type: "integer",
              description: "Maximum number of results (API may cap)",
              default: 3
            }
          },
          required: ["query"]
        }
      }
    }
  end

  @doc """
  Tool definition for web fetch.
  """
  @spec fetch_tool() :: map()
  def fetch_tool do
    %{
      type: "function",
      function: %{
        name: "web_fetch",
        description: "Fetch and read the content of a web page.",
        parameters: %{
          type: "object",
          properties: %{
            url: %{
              type: "string",
              description: "The URL to fetch"
            }
          },
          required: ["url"]
        }
      }
    }
  end
end
