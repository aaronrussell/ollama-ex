defmodule Ollama.OptionsTest do
  use Supertester.ExUnitFoundation, isolation: :basic

  alias Ollama.Options
  alias Ollama.Options.Presets

  describe "build/1" do
    test "creates options from keyword list" do
      assert {:ok, opts} = Options.build(temperature: 0.7, top_p: 0.9)
      assert opts.temperature == 0.7
      assert opts.top_p == 0.9
    end

    test "validates temperature range" do
      assert {:ok, _} = Options.build(temperature: 0.0)
      assert {:ok, _} = Options.build(temperature: 2.0)
      assert {:error, {:invalid_temperature, -0.1}} = Options.build(temperature: -0.1)
    end

    test "validates top_p range" do
      assert {:ok, _} = Options.build(top_p: 0.0)
      assert {:ok, _} = Options.build(top_p: 1.0)
      assert {:error, {:invalid_top_p, 1.5}} = Options.build(top_p: 1.5)
    end

    test "validates mirostat values" do
      assert {:ok, _} = Options.build(mirostat: 0)
      assert {:ok, _} = Options.build(mirostat: 1)
      assert {:ok, _} = Options.build(mirostat: 2)
      assert {:error, {:invalid_mirostat, 3}} = Options.build(mirostat: 3)
    end
  end

  describe "builder functions" do
    test "chain multiple options" do
      opts =
        Options.new()
        |> Options.temperature(0.5)
        |> Options.top_k(40)
        |> Options.seed(123)

      assert opts.temperature == 0.5
      assert opts.top_k == 40
      assert opts.seed == 123
    end
  end

  describe "to_map/1" do
    test "excludes nil values" do
      opts = Options.build!(temperature: 0.7)
      map = Options.to_map(opts)

      assert map[:temperature] == 0.7
      refute Map.has_key?(map, :top_p)
      refute Map.has_key?(map, :seed)
    end
  end

  describe "Access behaviour" do
    test "supports bracket access" do
      opts = Options.build!(temperature: 0.7)
      assert opts[:temperature] == 0.7
      assert opts["temperature"] == 0.7
    end
  end

  describe "presets" do
    test "returns preset options" do
      opts = Presets.creative()
      assert %Options{} = opts
      assert is_number(opts.temperature)
    end

    test "merges preset overrides" do
      opts = Presets.merge(:code, temperature: 0.3, num_predict: 100)
      assert opts.temperature == 0.3
      assert opts.num_predict == 100
    end
  end
end
