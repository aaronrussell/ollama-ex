defmodule Ollama.Types.ShowResponse do
  @moduledoc """
  Response from show_model.
  """

  use Ollama.Types.Base

  alias Ollama.Types.ModelDetails

  @type t :: %__MODULE__{
          modified_at: String.t() | nil,
          template: String.t() | nil,
          modelfile: String.t() | nil,
          license: String.t() | nil,
          parameters: String.t() | nil,
          capabilities: [String.t()] | nil,
          details: ModelDetails.t() | nil,
          model_info: map() | nil
        }

  defstruct [
    :modified_at,
    :template,
    :modelfile,
    :license,
    :parameters,
    :capabilities,
    :details,
    :model_info
  ]

  def from_map(map) do
    %__MODULE__{
      modified_at: map["modified_at"],
      template: map["template"],
      modelfile: map["modelfile"],
      license: map["license"],
      parameters: map["parameters"],
      capabilities: map["capabilities"],
      details: ModelDetails.from_map(map["details"]),
      model_info: map["model_info"] || map["modelinfo"]
    }
  end

  @doc """
  Check if model has a capability.
  """
  def has_capability?(%__MODULE__{capabilities: caps}, cap) when is_list(caps) do
    cap in caps
  end

  def has_capability?(_, _), do: false
end
