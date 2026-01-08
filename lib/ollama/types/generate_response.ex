defmodule Ollama.Types.GenerateResponse do
  @moduledoc """
  Response from the generate/completion endpoint.
  """

  use Ollama.Types.Base

  alias Ollama.Types.Logprob

  @type t :: %__MODULE__{
          model: String.t() | nil,
          created_at: String.t() | nil,
          response: String.t(),
          thinking: String.t() | nil,
          context: [integer()] | nil,
          done: boolean(),
          done_reason: String.t() | nil,
          total_duration: integer() | nil,
          load_duration: integer() | nil,
          prompt_eval_count: integer() | nil,
          prompt_eval_duration: integer() | nil,
          eval_count: integer() | nil,
          eval_duration: integer() | nil,
          logprobs: [Logprob.t()] | nil
        }

  defstruct [
    :model,
    :created_at,
    :thinking,
    :context,
    :done_reason,
    :total_duration,
    :load_duration,
    :prompt_eval_count,
    :prompt_eval_duration,
    :eval_count,
    :eval_duration,
    response: "",
    done: false,
    logprobs: nil
  ]

  @spec from_map(map()) :: t()
  def from_map(map) when is_map(map) do
    %__MODULE__{
      model: map["model"],
      created_at: map["created_at"],
      response: map["response"] || "",
      thinking: map["thinking"],
      context: map["context"],
      done: map["done"] || false,
      done_reason: map["done_reason"],
      total_duration: map["total_duration"],
      load_duration: map["load_duration"],
      prompt_eval_count: map["prompt_eval_count"],
      prompt_eval_duration: map["prompt_eval_duration"],
      eval_count: map["eval_count"],
      eval_duration: map["eval_duration"],
      logprobs: parse_logprobs(map["logprobs"])
    }
  end

  defp parse_logprobs(nil), do: nil
  defp parse_logprobs(probs), do: Enum.map(probs, &Logprob.from_map/1)

  @doc """
  Get tokens per second rate.
  """
  @spec tokens_per_second(t()) :: float() | nil
  def tokens_per_second(%__MODULE__{eval_count: count, eval_duration: duration})
      when is_integer(count) and is_integer(duration) and duration > 0 do
    count / (duration / 1_000_000_000)
  end

  def tokens_per_second(_), do: nil
end
