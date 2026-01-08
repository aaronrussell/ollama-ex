defmodule Ollama.WebTest do
  use ExUnit.Case, async: false

  alias Ollama.{RequestError, Web}
  alias Ollama.Web.{FetchResponse, SearchResponse}

  setup_all do
    {:ok, client: Ollama.init("http://localhost:4000")}
  end

  describe "search/2" do
    test "returns search results", %{client: client} do
      assert {:ok, %SearchResponse{} = res} =
               Web.search(client, query: "elixir", base_url: "http://localhost:4000/api")

      assert length(res.results) == 1
      assert hd(res.results).title == "Example"
    end

    test "validates missing query", %{client: client} do
      assert {:error, %RequestError{field: :query}} =
               Web.search(client, base_url: "http://localhost:4000/api")
    end
  end

  describe "authorization" do
    test "requires API key for cloud endpoints", %{client: client} do
      original = System.get_env("OLLAMA_API_KEY")

      try do
        System.delete_env("OLLAMA_API_KEY")

        assert {:error, %RequestError{reason: :missing_api_key}} =
                 Web.search(client, query: "elixir", base_url: "https://ollama.com/api")
      after
        if original,
          do: System.put_env("OLLAMA_API_KEY", original),
          else: System.delete_env("OLLAMA_API_KEY")
      end
    end

    test "rejects non-bearer authorization header" do
      client = Ollama.init(headers: [{"authorization", "Token nope"}])

      assert {:error, %RequestError{reason: :invalid_api_key}} =
               Web.search(client, query: "elixir", base_url: "https://ollama.com/api")
    end
  end

  describe "fetch/2" do
    test "returns page content", %{client: client} do
      assert {:ok, %FetchResponse{} = res} =
               Web.fetch(client,
                 url: "https://example.com",
                 base_url: "http://localhost:4000/api"
               )

      assert res.title == "Example"
      assert is_binary(res.content)
    end
  end
end
