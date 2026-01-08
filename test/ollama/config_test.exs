defmodule Ollama.ConfigTest do
  # Environment modification not async-safe
  use Supertester.ExUnitFoundation, isolation: :full_isolation, async: false

  describe "environment variable configuration" do
    test "OLLAMA_HOST sets default base URL" do
      original = System.get_env("OLLAMA_HOST")

      try do
        System.put_env("OLLAMA_HOST", "http://custom-host:8080")
        client = Ollama.init()
        assert client.req.options.base_url == "http://custom-host:8080/api"
      after
        if original,
          do: System.put_env("OLLAMA_HOST", original),
          else: System.delete_env("OLLAMA_HOST")
      end
    end

    test "explicit URL overrides OLLAMA_HOST" do
      original = System.get_env("OLLAMA_HOST")

      try do
        System.put_env("OLLAMA_HOST", "http://env-host:8080")
        client = Ollama.init("http://explicit-host:9090")
        assert client.req.options.base_url == "http://explicit-host:9090/api"
      after
        if original,
          do: System.put_env("OLLAMA_HOST", original),
          else: System.delete_env("OLLAMA_HOST")
      end
    end

    test "OLLAMA_API_KEY adds authorization header" do
      original = System.get_env("OLLAMA_API_KEY")

      try do
        System.put_env("OLLAMA_API_KEY", "test-api-key-123")
        client = Ollama.init()
        auth_header = client.req.headers["authorization"]
        assert auth_header == ["Bearer test-api-key-123"]
      after
        if original,
          do: System.put_env("OLLAMA_API_KEY", original),
          else: System.delete_env("OLLAMA_API_KEY")
      end
    end

    test "explicit headers override OLLAMA_API_KEY" do
      original = System.get_env("OLLAMA_API_KEY")

      try do
        System.put_env("OLLAMA_API_KEY", "env-key")
        client = Ollama.init(headers: [{"authorization", "Bearer explicit-key"}])
        auth_header = client.req.headers["authorization"]
        assert auth_header == ["Bearer explicit-key"]
      after
        if original,
          do: System.put_env("OLLAMA_API_KEY", original),
          else: System.delete_env("OLLAMA_API_KEY")
      end
    end
  end

  describe "host parsing" do
    test "accepts host without scheme" do
      client = Ollama.init("example.com")
      assert client.req.options.base_url == "http://example.com:11434/api"
    end

    test "accepts host with port only" do
      client = Ollama.init(":56789")
      assert client.req.options.base_url == "http://localhost:56789/api"
    end

    test "accepts host option" do
      client = Ollama.init(host: "example.com:56789")
      assert client.req.options.base_url == "http://example.com:56789/api"
    end
  end
end
