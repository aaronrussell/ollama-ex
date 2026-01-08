defmodule Ollama.ImageTest do
  use ExUnit.Case, async: false

  alias Ollama.Image

  @fixtures_path "test/fixtures/images"

  setup_all do
    {:ok, pid} = Bandit.start_link(plug: Ollama.MockServer, port: 4001)
    on_exit(fn -> Process.exit(pid, :normal) end)
    :ok
  end

  describe "encode/1" do
    test "encodes file path" do
      path = Path.join(@fixtures_path, "test.png")
      assert {:ok, encoded} = Image.encode(path)
      assert String.length(encoded) > 0
      assert {:ok, _} = Base.decode64(encoded)
    end

    test "encodes binary data" do
      png_binary = <<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A>>
      assert {:ok, encoded} = Image.encode(png_binary)
      assert {:ok, ^png_binary} = Base.decode64(encoded)
    end

    test "passes through valid base64" do
      original = Base.encode64("test data")
      assert {:ok, ^original} = Image.encode(original)
    end

    test "returns error for missing file" do
      assert {:error, {:file_not_found, _}} = Image.encode("./nonexistent.jpg")
    end

    test "returns error for invalid input" do
      assert {:error, {:invalid_image, _}} = Image.encode("not an image or path")
    end
  end

  describe "encode_all/1" do
    test "encodes multiple images" do
      inputs = [
        Path.join(@fixtures_path, "test.png"),
        <<0x89, 0x50, 0x4E, 0x47>>
      ]

      assert {:ok, [_, _]} = Image.encode_all(inputs)
    end

    test "fails fast on first error" do
      inputs = ["./exists.png", "./missing.jpg"]
      assert {:error, _} = Image.encode_all(inputs)
    end
  end

  describe "from_url/2" do
    test "downloads and encodes image" do
      assert {:ok, encoded} = Image.from_url("http://localhost:4001/image")
      assert {:ok, _} = Base.decode64(encoded)
    end

    test "returns error for non-200 response" do
      assert {:error, {:http_error, 404}} = Image.from_url("http://localhost:4001/does-not-exist")
    end
  end
end
