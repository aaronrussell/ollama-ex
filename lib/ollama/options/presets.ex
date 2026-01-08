defmodule Ollama.Options.Presets do
  @moduledoc """
  Pre-configured option sets for common use cases.
  """

  alias Ollama.Options

  @spec creative() :: Options.t()
  def creative do
    Options.build!(
      temperature: 1.0,
      top_p: 0.95,
      top_k: 60,
      repeat_penalty: 1.1
    )
  end

  @spec precise() :: Options.t()
  def precise do
    Options.build!(
      temperature: 0.1,
      top_p: 0.5,
      top_k: 10,
      seed: 42
    )
  end

  @spec code() :: Options.t()
  def code do
    Options.build!(
      temperature: 0.2,
      top_p: 0.9,
      repeat_penalty: 1.0,
      stop: ["\n\n", "```"]
    )
  end

  @spec chat() :: Options.t()
  def chat do
    Options.build!(
      temperature: 0.7,
      top_p: 0.9,
      repeat_penalty: 1.1,
      num_predict: 512
    )
  end

  @spec fast() :: Options.t()
  def fast do
    Options.build!(
      num_ctx: 2048,
      num_predict: 256,
      temperature: 0.7
    )
  end

  @spec large_context() :: Options.t()
  def large_context do
    Options.build!(
      num_ctx: 8192,
      num_batch: 512
    )
  end

  @doc """
  Merge a preset with custom options.
  """
  @spec merge(atom(), keyword()) :: Options.t()
  def merge(preset_name, overrides) when is_atom(preset_name) do
    preset = apply(__MODULE__, preset_name, [])
    override_opts = Options.build!(overrides)

    Map.merge(preset, override_opts, fn _key, base, override ->
      override || base
    end)
  end
end
