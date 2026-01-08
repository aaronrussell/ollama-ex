defmodule Ollama.ToolTest do
  use ExUnit.Case, async: true

  alias Ollama.Tool

  describe "define/2" do
    test "creates valid tool definition" do
      tool =
        Tool.define(:test_func,
          description: "Test function",
          parameters: [
            name: [type: :string, required: true],
            count: [type: :integer, default: 10]
          ]
        )

      assert tool.type == "function"
      assert tool.function.name == "test_func"
      assert tool.function.description == "Test function"
      assert tool.function.parameters.type == "object"
      assert tool.function.parameters.required == ["name"]
    end
  end

  describe "from_function/1" do
    defmodule TestModule do
      @doc """
      Add numbers.

      ## Parameters
      * `a` - First number
      * `b` - Second number
      """
      @spec add(a :: integer(), b :: integer()) :: integer()
      def add(a, b), do: a + b
    end

    test "converts function reference" do
      assert {:ok, tool} = Tool.from_function(&TestModule.add/2)
      assert tool.function.name == "add"
      params = tool.function.parameters
      assert params.type == "object"
      assert map_size(params.properties) >= 2
    end

    test "fails for anonymous function" do
      assert {:error, :anonymous_function} = Tool.from_function(fn x -> x end)
    end
  end

  describe "prepare/1" do
    defmodule PrepareModule do
      @doc "Multiply two numbers"
      @spec multiply(a :: number(), b :: number()) :: number()
      def multiply(a, b), do: a * b
    end

    test "converts mixed list" do
      manual = %{type: "function", function: %{name: "manual"}}

      assert {:ok, [tool1, tool2]} =
               Tool.prepare([
                 &PrepareModule.multiply/2,
                 manual
               ])

      assert tool1.function.name == "multiply"
      assert tool2.function.name == "manual"
    end

    test "accepts custom tool types" do
      manual = %{type: "custom_type", function: %{name: "manual"}}

      assert {:ok, [tool]} = Tool.prepare([manual])
      assert tool.type == "custom_type"
    end

    test "accepts maps without a type" do
      manual = %{function: %{name: "manual"}}

      assert {:ok, [tool]} = Tool.prepare([manual])
      assert tool.function.name == "manual"
    end

    test "returns error for invalid tool" do
      assert {:error, {:invalid_tool, :bad}} = Tool.prepare([:bad])
    end
  end
end
