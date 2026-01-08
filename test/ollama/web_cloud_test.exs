defmodule Ollama.WebCloudTest do
  use ExUnit.Case, async: true

  @moduletag :cloud_api

  setup_all do
    key = System.get_env("OLLAMA_API_KEY")

    if key in [nil, ""] do
      flunk("OLLAMA_API_KEY is required to run cloud_api tests.")
    end

    {:ok, client: Ollama.init()}
  end

  test "web_search returns results", %{client: client} do
    assert {:ok, %Ollama.Web.SearchResponse{results: results}} =
             Ollama.web_search(client, query: "elixir", max_results: 1)

    assert is_list(results)
  end

  test "web_fetch returns content", %{client: client} do
    assert {:ok, %Ollama.Web.FetchResponse{content: content}} =
             Ollama.web_fetch(client, url: "https://ollama.com")

    assert is_binary(content)
  end
end
