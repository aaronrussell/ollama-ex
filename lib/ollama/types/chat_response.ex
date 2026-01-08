defmodule Ollama.Types.ChatResponse do
  @moduledoc """
  Response from the chat endpoint.
  """

  use Ollama.Types.Base

  alias Ollama.Types.{Logprob, Message}

  @type t :: %__MODULE__{
          model: String.t() | nil,
          created_at: String.t() | nil,
          message: Message.t() | nil,
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
    :message,
    :done_reason,
    :total_duration,
    :load_duration,
    :prompt_eval_count,
    :prompt_eval_duration,
    :eval_count,
    :eval_duration,
    done: false,
    logprobs: nil
  ]

  @spec from_map(map()) :: t()
  def from_map(map) when is_map(map) do
    %__MODULE__{
      model: map["model"],
      created_at: map["created_at"],
      message: parse_message(map["message"]),
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

  defp parse_message(nil), do: nil
  defp parse_message(msg), do: Message.from_map(msg)

  defp parse_logprobs(nil), do: nil
  defp parse_logprobs(probs), do: Enum.map(probs, &Logprob.from_map/1)
end
