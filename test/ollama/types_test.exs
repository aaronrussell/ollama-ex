defmodule Ollama.TypesTest do
  use ExUnit.Case, async: true

  alias Ollama.Types.{
    ChatResponse,
    EmbeddingsResponse,
    EmbedResponse,
    GenerateResponse,
    Logprob,
    Message,
    ModelDetails,
    ModelInfo,
    ListResponse,
    ProcessResponse,
    ProgressResponse,
    ShowResponse,
    StatusResponse,
    ToolCall
  }

  describe "Logprob" do
    test "parses and computes probability" do
      logprob = Logprob.from_map(%{"token" => "Hello", "logprob" => -0.5})
      assert logprob.token == "Hello"
      assert logprob.logprob == -0.5
      assert Logprob.probability(logprob) > 0.0
    end
  end

  describe "ToolCall" do
    test "parses arguments from JSON" do
      call =
        ToolCall.from_map(%{
          "function" => %{"name" => "get_weather", "arguments" => ~s({"city":"Paris"})}
        })

      assert ToolCall.name(call) == "get_weather"
      assert ToolCall.arguments(call)["city"] == "Paris"
    end
  end

  describe "Message" do
    test "parses tool calls" do
      msg =
        Message.from_map(%{
          "role" => "assistant",
          "content" => "",
          "tool_calls" => [%{"function" => %{"name" => "search", "arguments" => "{}"}}]
        })

      assert msg.role == "assistant"
      assert length(msg.tool_calls) == 1
      assert ToolCall.name(hd(msg.tool_calls)) == "search"
    end
  end

  describe "GenerateResponse" do
    test "parses response and tokens_per_second" do
      res =
        GenerateResponse.from_map(%{
          "model" => "llama3",
          "response" => "Hi",
          "eval_count" => 10,
          "eval_duration" => 1_000_000_000,
          "logprobs" => [%{"token" => "Hi", "logprob" => -0.2}]
        })

      assert res.model == "llama3"
      assert res.response == "Hi"
      assert is_number(GenerateResponse.tokens_per_second(res))
    end
  end

  describe "ChatResponse" do
    test "parses nested message" do
      res =
        ChatResponse.from_map(%{
          "model" => "llama3",
          "message" => %{"role" => "assistant", "content" => "Hello"}
        })

      assert res.message.content == "Hello"
      assert res["model"] == "llama3"
    end
  end

  describe "EmbedResponse" do
    test "returns first embedding and dimensions" do
      res =
        EmbedResponse.from_map(%{
          "model" => "nomic-embed-text",
          "embeddings" => [[0.1, 0.2, 0.3]]
        })

      assert EmbedResponse.first(res) == [0.1, 0.2, 0.3]
      assert EmbedResponse.dimensions(res) == 3
    end
  end

  describe "EmbeddingsResponse" do
    test "parses embedding and dimensions" do
      res =
        EmbeddingsResponse.from_map(%{
          "embedding" => [0.1, 0.2, 0.3, 0.4]
        })

      assert res.embedding == [0.1, 0.2, 0.3, 0.4]
      assert EmbeddingsResponse.dimensions(res) == 4
    end
  end

  describe "ModelInfo" do
    test "parses ModelDetails" do
      details = ModelDetails.from_map(%{"family" => "llama", "format" => "gguf"})
      assert details.family == "llama"
      assert details.format == "gguf"
    end

    test "parses model info details" do
      info =
        ModelInfo.from_map(%{
          "name" => "llama3",
          "details" => %{"family" => "llama", "format" => "gguf"}
        })

      assert info.name == "llama3"
      assert info.details.family == "llama"
    end
  end

  describe "ListResponse" do
    test "parses list of models" do
      res =
        ListResponse.from_map(%{
          "models" => [
            %{"name" => "llama3"},
            %{"name" => "mistral"}
          ]
        })

      assert length(res.models) == 2
      assert Enum.at(res.models, 0).name == "llama3"
    end
  end

  describe "ProcessResponse" do
    test "parses running models" do
      res =
        ProcessResponse.from_map(%{
          "models" => [
            %{"name" => "llama3", "size" => 123}
          ]
        })

      assert length(res.models) == 1
      assert hd(res.models).size == 123
    end
  end

  describe "ShowResponse" do
    test "parses show response" do
      res =
        ShowResponse.from_map(%{
          "modelfile" => "FROM llama3",
          "details" => %{"format" => "gguf"}
        })

      assert res.modelfile == "FROM llama3"
      assert res.details.format == "gguf"
    end
  end

  describe "StatusResponse" do
    test "parses status" do
      res = StatusResponse.from_map(%{"status" => "success"})
      assert res.status == "success"
    end
  end

  describe "ProgressResponse" do
    test "parses progress" do
      res = ProgressResponse.from_map(%{"status" => "pulling", "total" => 100, "completed" => 50})
      assert res.status == "pulling"
      assert res.completed == 50
    end
  end
end
