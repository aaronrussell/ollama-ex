defmodule Ollama.ResponseFormatTest do
  use Supertester.ExUnitFoundation, isolation: :full_isolation, async: false

  alias Ollama.Types.{
    ChatResponse,
    EmbedResponse,
    EmbeddingsResponse,
    GenerateResponse,
    ListResponse
  }

  setup_all do
    {:ok, client: Ollama.init("http://localhost:4000")}
  end

  describe "response_format option" do
    test "chat returns struct", %{client: client} do
      assert {:ok, %ChatResponse{} = res} =
               Ollama.chat(client,
                 model: "llama2",
                 messages: [%{role: "user", content: "Hi"}],
                 response_format: :struct
               )

      assert res.message.role == "assistant"
    end

    test "completion returns struct", %{client: client} do
      assert {:ok, %GenerateResponse{} = res} =
               Ollama.completion(client,
                 model: "llama2",
                 prompt: "Hi",
                 response_format: :struct
               )

      assert is_binary(res.response)
    end

    test "embed returns struct", %{client: client} do
      assert {:ok, %EmbedResponse{} = res} =
               Ollama.embed(client,
                 model: "nomic-embed-text",
                 input: "Hello",
                 response_format: :struct
               )

      assert is_list(res.embeddings)
    end

    test "embeddings returns struct", %{client: client} do
      # Use apply/3 to avoid deprecation warning.
      assert {:ok, %EmbeddingsResponse{} = res} =
               apply(Ollama, :embeddings, [
                 client,
                 [
                   model: "llama2",
                   prompt: "Hello",
                   response_format: :struct
                 ]
               ])

      assert is_list(res.embedding)
    end

    test "chat stream yields structs", %{client: client} do
      assert {:ok, stream} =
               Ollama.chat(client,
                 model: "llama2",
                 messages: [%{role: "user", content: "Hi"}],
                 stream: true,
                 response_format: :struct
               )

      [first | _] = Enum.take(stream, 1)
      assert %ChatResponse{} = first
    end
  end

  describe "response_format app env" do
    test "list_models returns struct when configured", %{client: client} do
      original = Application.get_env(:ollama, :response_format)

      try do
        Application.put_env(:ollama, :response_format, :struct)
        assert {:ok, %ListResponse{} = res} = Ollama.list_models(client)
        assert is_list(res.models)
      after
        if is_nil(original) do
          Application.delete_env(:ollama, :response_format)
        else
          Application.put_env(:ollama, :response_format, original)
        end
      end
    end
  end
end
