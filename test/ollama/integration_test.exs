defmodule Ollama.IntegrationTest do
  use Supertester.ExUnitFoundation, isolation: :full_isolation, async: false

  alias Ollama.Options

  defmodule ExampleTools do
    @doc "Add two numbers together."
    @spec add(integer(), integer()) :: integer()
    def add(a, b), do: a + b
  end

  setup_all do
    {:ok, client: Ollama.init("http://localhost:4000")}
  end

  describe "options normalization" do
    test "accepts Options struct", %{client: client} do
      opts = %Options{temperature: 0.2}

      assert {:ok, res} =
               Ollama.chat(client,
                 model: "llama2",
                 messages: [%{role: "user", content: "Hi"}],
                 options: opts
               )

      assert res["model"] == "llama2"
    end

    test "accepts options keyword list", %{client: client} do
      assert {:ok, res} =
               Ollama.chat(client,
                 model: "llama2",
                 messages: [%{role: "user", content: "Hi"}],
                 options: [temperature: 0.2]
               )

      assert res["model"] == "llama2"
    end
  end

  describe "tool conversion" do
    test "accepts function tools", %{client: client} do
      assert {:ok, res} =
               Ollama.chat(client,
                 model: "llama2",
                 messages: [%{role: "user", content: "Add 2 and 3"}],
                 tools: [&ExampleTools.add/2]
               )

      assert res["model"] == "llama2"
    end
  end

  describe "image auto encoding" do
    test "encodes completion image paths", %{client: client} do
      image_path = Path.expand("../fixtures/images/test.png", __DIR__)

      assert {:ok, res} =
               Ollama.completion(client,
                 model: "llama2",
                 prompt: "Describe this image",
                 images: [image_path]
               )

      assert res["model"] == "llama2"
    end

    test "encodes chat message images", %{client: client} do
      image_path = Path.expand("../fixtures/images/test.jpg", __DIR__)

      assert {:ok, res} =
               Ollama.chat(client,
                 model: "llama2",
                 messages: [
                   %{role: "user", content: "Describe this image", images: [image_path]}
                 ]
               )

      assert res["model"] == "llama2"
    end
  end
end
