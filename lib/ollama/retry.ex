defmodule Ollama.Retry do
  @moduledoc """
  Retry utilities for transient errors.
  """

  alias Ollama.ResponseError

  @default_max_attempts 3
  @default_base_delay 1_000
  @default_max_delay 30_000

  @type opts :: [
          max_attempts: pos_integer(),
          base_delay: pos_integer(),
          max_delay: pos_integer(),
          retry_on: (term() -> boolean())
        ]

  @doc """
  Execute function with exponential backoff retry.

  ## Options

    * `:max_attempts` - Maximum retry attempts (default: 3)
    * `:base_delay` - Initial delay in ms (default: 1000)
    * `:max_delay` - Maximum delay in ms (default: 30000)
    * `:retry_on` - Function to determine if error is retryable
  """
  @spec with_backoff((-> {:ok, term()} | {:error, term()}), opts()) ::
          {:ok, term()} | {:error, term()}
  def with_backoff(fun, opts \\ []) do
    max_attempts = Keyword.get(opts, :max_attempts, @default_max_attempts)
    base_delay = Keyword.get(opts, :base_delay, @default_base_delay)
    max_delay = Keyword.get(opts, :max_delay, @default_max_delay)
    retry_on = Keyword.get(opts, :retry_on, &default_retry_on/1)

    do_retry(fun, 1, max_attempts, base_delay, max_delay, retry_on)
  end

  defp do_retry(fun, attempt, max_attempts, _base_delay, _max_delay, _retry_on)
       when attempt > max_attempts do
    fun.()
  end

  defp do_retry(fun, attempt, max_attempts, base_delay, max_delay, retry_on) do
    case fun.() do
      {:ok, _} = success ->
        success

      {:error, error} = failure ->
        if retry_on.(error) and attempt < max_attempts do
          delay = calculate_delay(attempt, base_delay, max_delay)
          Process.sleep(delay)
          do_retry(fun, attempt + 1, max_attempts, base_delay, max_delay, retry_on)
        else
          failure
        end
    end
  end

  defp calculate_delay(attempt, base_delay, max_delay) do
    delay = base_delay * :math.pow(2, attempt - 1)
    jitter_max = max(round(delay * 0.1), 1)
    jitter = :rand.uniform(jitter_max) - 1
    min(round(delay + jitter), max_delay)
  end

  defp default_retry_on(%ResponseError{} = e), do: ResponseError.retryable?(e)
  defp default_retry_on(_), do: false
end
