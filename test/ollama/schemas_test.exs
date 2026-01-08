defmodule Ollama.SchemasTest do
  use ExUnit.Case, async: true

  describe "chat schema validation" do
    test "requires model parameter" do
      assert {:error, _} =
               NimbleOptions.validate(
                 [
                   messages: [%{role: "user", content: "Hi"}]
                 ],
                 Ollama.Schemas.schema(:chat)
               )
    end

    test "requires messages parameter" do
      assert {:error, _} =
               NimbleOptions.validate(
                 [
                   model: "llama2"
                 ],
                 Ollama.Schemas.schema(:chat)
               )
    end

    test "validates stream option type" do
      assert {:ok, _} =
               NimbleOptions.validate(
                 [
                   model: "llama2",
                   messages: [%{role: "user", content: "Hi"}],
                   stream: true
                 ],
                 Ollama.Schemas.schema(:chat)
               )

      assert {:ok, _} =
               NimbleOptions.validate(
                 [
                   model: "llama2",
                   messages: [%{role: "user", content: "Hi"}],
                   stream: self()
                 ],
                 Ollama.Schemas.schema(:chat)
               )
    end

    test "validates think option accepts boolean and strings" do
      for think_val <- [true, false, "low", "medium", "high"] do
        assert {:ok, _} =
                 NimbleOptions.validate(
                   [
                     model: "llama2",
                     messages: [%{role: "user", content: "Hi"}],
                     think: think_val
                   ],
                   Ollama.Schemas.schema(:chat)
                 )
      end
    end

    test "validates logprobs is boolean" do
      assert {:ok, _} =
               NimbleOptions.validate(
                 [
                   model: "llama2",
                   messages: [%{role: "user", content: "Hi"}],
                   logprobs: true
                 ],
                 Ollama.Schemas.schema(:chat)
               )
    end

    test "validates top_logprobs is integer" do
      assert {:ok, _} =
               NimbleOptions.validate(
                 [
                   model: "llama2",
                   messages: [%{role: "user", content: "Hi"}],
                   top_logprobs: 5
                 ],
                 Ollama.Schemas.schema(:chat)
               )
    end
  end

  describe "completion schema validation" do
    test "requires model parameter" do
      assert {:error, _} =
               NimbleOptions.validate(
                 [
                   prompt: "Hello"
                 ],
                 Ollama.Schemas.schema(:completion)
               )
    end

    test "validates suffix parameter" do
      assert {:ok, _} =
               NimbleOptions.validate(
                 [
                   model: "codellama",
                   prompt: "def add(",
                   suffix: ")"
                 ],
                 Ollama.Schemas.schema(:completion)
               )
    end
  end

  describe "embed schema validation" do
    test "validates dimensions parameter" do
      assert {:ok, _} =
               NimbleOptions.validate(
                 [
                   model: "nomic-embed-text",
                   input: "Hello",
                   dimensions: 256
                 ],
                 Ollama.Schemas.schema(:embed)
               )
    end
  end
end
