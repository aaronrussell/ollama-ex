defmodule Ollama.Options do
  @moduledoc """
  Model inference options.

  Provides typed, validated options for controlling model behavior.
  All options are optional - only set what you need to change from defaults.
  """

  @behaviour Access

  @fields [
    # Load-time options
    :numa,
    :num_ctx,
    :num_batch,
    :num_gpu,
    :main_gpu,
    :low_vram,
    :f16_kv,
    :logits_all,
    :vocab_only,
    :use_mmap,
    :use_mlock,
    :embedding_only,
    :num_thread,
    # Runtime options
    :num_keep,
    :seed,
    :num_predict,
    :top_k,
    :top_p,
    :tfs_z,
    :typical_p,
    :repeat_last_n,
    :temperature,
    :repeat_penalty,
    :presence_penalty,
    :frequency_penalty,
    :mirostat,
    :mirostat_tau,
    :mirostat_eta,
    :penalize_newline,
    :stop
  ]

  @type t :: %__MODULE__{
          # Load-time
          numa: boolean() | nil,
          num_ctx: pos_integer() | nil,
          num_batch: pos_integer() | nil,
          num_gpu: integer() | nil,
          main_gpu: non_neg_integer() | nil,
          low_vram: boolean() | nil,
          f16_kv: boolean() | nil,
          logits_all: boolean() | nil,
          vocab_only: boolean() | nil,
          use_mmap: boolean() | nil,
          use_mlock: boolean() | nil,
          embedding_only: boolean() | nil,
          num_thread: pos_integer() | nil,
          # Runtime
          num_keep: integer() | nil,
          seed: integer() | nil,
          num_predict: integer() | nil,
          top_k: non_neg_integer() | nil,
          top_p: float() | nil,
          tfs_z: float() | nil,
          typical_p: float() | nil,
          repeat_last_n: integer() | nil,
          temperature: float() | nil,
          repeat_penalty: float() | nil,
          presence_penalty: float() | nil,
          frequency_penalty: float() | nil,
          mirostat: 0 | 1 | 2 | nil,
          mirostat_tau: float() | nil,
          mirostat_eta: float() | nil,
          penalize_newline: boolean() | nil,
          stop: [String.t()] | nil,
          extra: map()
        }

  defstruct @fields ++ [extra: %{}]

  @doc """
  Create a new empty options struct.
  """
  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc """
  Build options from keyword list with validation.
  """
  @spec build(keyword()) :: {:ok, t()} | {:error, term()}
  def build(opts) when is_list(opts) do
    Enum.reduce_while(opts, {:ok, new()}, fn {key, value}, {:ok, acc} ->
      key = normalize_key(key)

      if key in @fields do
        case validate_option(key, value) do
          :ok -> {:cont, {:ok, Map.put(acc, key, value)}}
          {:error, _} = error -> {:halt, error}
        end
      else
        {:cont, {:ok, put_extra(acc, key, value)}}
      end
    end)
  end

  @doc """
  Build options, raising on validation error.
  """
  @spec build!(keyword()) :: t()
  def build!(opts) do
    case build(opts) do
      {:ok, result} -> result
      {:error, reason} -> raise ArgumentError, "Invalid option: #{inspect(reason)}"
    end
  end

  @doc """
  Set temperature (>= 0.0).
  """
  @spec temperature(t(), float()) :: t()
  def temperature(%__MODULE__{} = opts, value) when is_number(value) and value >= 0.0 do
    %{opts | temperature: value}
  end

  @doc """
  Set top_k sampling (0 = disabled).
  """
  @spec top_k(t(), non_neg_integer()) :: t()
  def top_k(%__MODULE__{} = opts, value) when is_integer(value) and value >= 0 do
    %{opts | top_k: value}
  end

  @doc """
  Set top_p/nucleus sampling (0.0-1.0).
  """
  @spec top_p(t(), float()) :: t()
  def top_p(%__MODULE__{} = opts, value)
      when is_number(value) and value >= 0.0 and value <= 1.0 do
    %{opts | top_p: value}
  end

  @doc """
  Set random seed for reproducibility.
  """
  @spec seed(t(), integer()) :: t()
  def seed(%__MODULE__{} = opts, value) when is_integer(value) do
    %{opts | seed: value}
  end

  @doc """
  Set max tokens to generate (-1 = unlimited).
  """
  @spec num_predict(t(), integer()) :: t()
  def num_predict(%__MODULE__{} = opts, value) when is_integer(value) do
    %{opts | num_predict: value}
  end

  @doc """
  Set context window size.
  """
  @spec num_ctx(t(), pos_integer()) :: t()
  def num_ctx(%__MODULE__{} = opts, value) when is_integer(value) and value > 0 do
    %{opts | num_ctx: value}
  end

  @doc """
  Set repeat penalty (1.0 = no penalty).
  """
  @spec repeat_penalty(t(), float()) :: t()
  def repeat_penalty(%__MODULE__{} = opts, value) when is_number(value) and value >= 0.0 do
    %{opts | repeat_penalty: value}
  end

  @doc """
  Set stop sequences.
  """
  @spec stop(t(), [String.t()]) :: t()
  def stop(%__MODULE__{} = opts, value) when is_list(value) do
    %{opts | stop: value}
  end

  @doc """
  Set number of GPU layers (-1 = all, 0 = CPU only).
  """
  @spec num_gpu(t(), integer()) :: t()
  def num_gpu(%__MODULE__{} = opts, value) when is_integer(value) do
    %{opts | num_gpu: value}
  end

  @doc """
  Enable/disable NUMA.
  """
  @spec numa(t(), boolean()) :: t()
  def numa(%__MODULE__{} = opts, value) when is_boolean(value) do
    %{opts | numa: value}
  end

  @doc """
  Enable/disable memory mapping.
  """
  @spec use_mmap(t(), boolean()) :: t()
  def use_mmap(%__MODULE__{} = opts, value) when is_boolean(value) do
    %{opts | use_mmap: value}
  end

  @doc """
  Set mirostat mode (0 = disabled, 1 = v1, 2 = v2).
  """
  @spec mirostat(t(), 0 | 1 | 2) :: t()
  def mirostat(%__MODULE__{} = opts, value) when value in [0, 1, 2] do
    %{opts | mirostat: value}
  end

  @doc """
  Set presence penalty (0.0-2.0).
  """
  @spec presence_penalty(t(), float()) :: t()
  def presence_penalty(%__MODULE__{} = opts, value) when is_number(value) do
    %{opts | presence_penalty: value}
  end

  @doc """
  Set frequency penalty (0.0-2.0).
  """
  @spec frequency_penalty(t(), float()) :: t()
  def frequency_penalty(%__MODULE__{} = opts, value) when is_number(value) do
    %{opts | frequency_penalty: value}
  end

  @doc """
  Convert options struct to map for API request.

  Excludes nil values and merges custom keys.
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = opts) do
    opts
    |> Map.from_struct()
    |> Map.delete(:extra)
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Map.new()
    |> Map.merge(opts.extra)
  end

  @doc """
  Create options from a map.
  """
  @spec from_map(map()) :: {:ok, t()} | {:error, term()}
  def from_map(map) when is_map(map) do
    map
    |> Enum.map(fn {k, v} -> {normalize_key(k), v} end)
    |> build()
  end

  defp normalize_key(key) when is_atom(key), do: key

  defp normalize_key(key) when is_binary(key) do
    try do
      atom = String.to_existing_atom(key)
      if atom in @fields, do: atom, else: key
    rescue
      ArgumentError -> key
    end
  end

  defp put_extra(%__MODULE__{} = opts, key, value) do
    extra = Map.get(opts, :extra, %{})
    %{opts | extra: Map.put(extra, to_string(key), value)}
  end

  defp validate_option(:temperature, v) when is_number(v) and v >= 0.0, do: :ok
  defp validate_option(:temperature, v), do: {:error, {:invalid_temperature, v}}

  defp validate_option(:top_k, v) when is_integer(v) and v >= 0, do: :ok
  defp validate_option(:top_k, v), do: {:error, {:invalid_top_k, v}}

  defp validate_option(:top_p, v) when is_number(v) and v >= 0.0 and v <= 1.0, do: :ok
  defp validate_option(:top_p, v), do: {:error, {:invalid_top_p, v}}

  defp validate_option(:seed, v) when is_integer(v), do: :ok
  defp validate_option(:seed, v), do: {:error, {:invalid_seed, v}}

  defp validate_option(:num_ctx, v) when is_integer(v) and v > 0, do: :ok
  defp validate_option(:num_ctx, v), do: {:error, {:invalid_num_ctx, v}}

  defp validate_option(:num_predict, v) when is_integer(v), do: :ok
  defp validate_option(:num_predict, v), do: {:error, {:invalid_num_predict, v}}

  defp validate_option(:num_gpu, v) when is_integer(v), do: :ok
  defp validate_option(:num_gpu, v), do: {:error, {:invalid_num_gpu, v}}

  defp validate_option(:mirostat, v) when v in [0, 1, 2], do: :ok
  defp validate_option(:mirostat, v), do: {:error, {:invalid_mirostat, v}}

  defp validate_option(:stop, v) when is_list(v), do: :ok
  defp validate_option(:stop, v), do: {:error, {:invalid_stop, v}}

  defp validate_option(key, v)
       when is_boolean(v) and
              key in [
                :numa,
                :low_vram,
                :f16_kv,
                :logits_all,
                :vocab_only,
                :use_mmap,
                :use_mlock,
                :embedding_only,
                :penalize_newline
              ],
       do: :ok

  defp validate_option(key, v)
       when is_number(v) and
              key in [
                :repeat_penalty,
                :presence_penalty,
                :frequency_penalty,
                :tfs_z,
                :typical_p,
                :mirostat_tau,
                :mirostat_eta
              ],
       do: :ok

  defp validate_option(key, v)
       when is_integer(v) and
              key in [:num_batch, :main_gpu, :num_thread, :num_keep, :repeat_last_n],
       do: :ok

  defp validate_option(_key, _value), do: :ok

  @impl Access
  def fetch(opts, key) when is_atom(key), do: Map.fetch(opts, key)

  def fetch(opts, key) when is_binary(key) do
    case normalize_key(key) do
      atom when is_atom(atom) -> fetch(opts, atom)
      string -> Map.fetch(opts.extra, string)
    end
  end

  @impl Access
  def get_and_update(opts, key, fun), do: Map.get_and_update(opts, key, fun)

  @impl Access
  def pop(opts, key), do: Map.pop(opts, key)
end
