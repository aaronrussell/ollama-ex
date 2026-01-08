defmodule Ollama do
  @version Keyword.fetch!(Mix.Project.config(), :version)
  @moduledoc """
  Elixir client for the Ollama API.

  ## Quick Start

      client = Ollama.init()
      {:ok, response} = Ollama.chat(client,
        model: "llama3.2",
        messages: [%{role: "user", content: "Hello!"}]
      )

  ## Client Configuration

      # Default (localhost:11434)
      client = Ollama.init()

      # Custom host
      client = Ollama.init("http://ollama.example.com:11434")

      # With options
      client = Ollama.init(
        base_url: "http://localhost:11434/api",
        receive_timeout: 120_000,
        headers: [{"authorization", "Bearer token"}]
      )

  ## Streaming

  Two modes are available:

  ### Enumerable Mode

      {:ok, stream} = Ollama.chat(client, model: "llama3.2", messages: msgs, stream: true)
      Enum.each(stream, &IO.inspect/1)

  ### Process Mode (for GenServer/LiveView)

      {:ok, task} = Ollama.chat(client, model: "llama3.2", messages: msgs, stream: self())
      # Receive messages with handle_info/2

  See the [Streaming Guide](guides/streaming.md) for details.

  ## Error Handling

  All functions return `{:ok, result}` or `{:error, reason}`.

      case Ollama.chat(client, opts) do
        {:ok, response} -> handle_success(response)
        {:error, %Ollama.ConnectionError{} = error} -> handle_connection(error)
        {:error, %Ollama.ResponseError{status: 404}} -> handle_not_found()
        {:error, %Ollama.ResponseError{status: status}} -> handle_error(status)
      end

  ## Links

  - [GitHub](https://github.com/lebrunel/ollama-ex)
  - [Ollama API Docs](https://github.com/ollama/ollama/blob/main/docs/api.md)
  """
  use Ollama.Schemas
  alias Ollama.{Blob, ConnectionError, Image, Options, RequestError, ResponseError, Tool, Web}
  defstruct [:req]

  @typedoc "Client struct"
  @type client() :: %__MODULE__{
          req: Req.Request.t()
        }

  @permissive_map {:map, {:or, [:atom, :string]}, :any}

  schema(:chat_message,
    role: [
      type: {:in, ["system", "user", "assistant", "tool"]},
      required: true,
      doc: "The role of the message, either `system`, `user`, `assistant` or `tool`."
    ],
    content: [
      type: {:or, [:string, nil]},
      doc: "The content of the message. Optional for tool calls."
    ],
    images: [
      type: {:list, :string},
      doc: "*(optional)* List of Base64 encoded images (for multimodal models only)."
    ],
    tool_name: [
      type: :string,
      doc: "*(optional)* Tool name for tool responses."
    ],
    tool_calls: [
      type: {:list, @permissive_map},
      doc: "*(optional)* List of tools the model wants to use."
    ]
  )

  @typedoc """
  Chat message

  A chat message is a `t:map/0` with the following fields:

  #{doc(:chat_message)}
  """
  @type message() :: unquote(NimbleOptions.option_typespec(schema_def(:chat_message)))

  schema(:tool_def,
    type: [
      type: :string,
      default: "function",
      doc: "Type of tool. Defaults to `\"function\"`."
    ],
    function: [
      type: :map,
      keys: [
        name: [
          type: :string,
          required: true,
          doc: "The name of the function to be called."
        ],
        description: [
          type: :string,
          doc: "A description of what the function does."
        ],
        parameters: [
          type: @permissive_map,
          required: true,
          doc: "The parameters the functions accepts."
        ]
      ],
      required: true
    ]
  )

  @typedoc """
  Tool definition

  A tool definition is a `t:map/0` with the following fields:

  #{doc(:tool_def)}
  """
  @type tool() :: unquote(NimbleOptions.option_typespec(schema_def(:tool_def)))

  @typedoc "Client response"
  @type response() ::
          {:ok, map() | boolean() | binary() | Enumerable.t() | Task.t()}
          | {:error, term()}

  @typep req_response() ::
           {:ok, Req.Response.t() | Task.t() | Enumerable.t()}
           | {:error, term()}

  @doc """
  Initializes a new Ollama client.

  ## Parameters

  - `opts` - Base URL, host string, `%URI{}`, `Req.Request`, or keyword options for `Req.new/1`.

  ## Environment Variables

  - `OLLAMA_HOST` - Default Ollama server URL (default: http://localhost:11434)
  - `OLLAMA_API_KEY` - Bearer token for API authentication

  ## Examples

      # Uses OLLAMA_HOST or defaults to localhost:11434
      client = Ollama.init()

      # Explicit URL (overrides OLLAMA_HOST)
      client = Ollama.init("http://ollama.example.com:11434")

      # Host strings without a scheme use http:// and default port 11434
      client = Ollama.init("ollama.example.com")
      client = Ollama.init(":11434")

      # With host option
      client = Ollama.init(host: "ollama.example.com:11434")

      # With custom options
      client = Ollama.init(receive_timeout: 120_000)

  ## Returns

  - `t:client/0` - Configured Ollama client

  ## See Also

  - `chat/2` - Chat API requests
  - `completion/2` - Completion API requests

  """
  @spec init(Req.url() | keyword() | Req.Request.t()) :: client()
  def init(opts \\ [])

  def init(url) when is_binary(url),
    do: struct(__MODULE__, req: init_req(base_url: url))

  def init(%URI{} = uri),
    do: init(URI.to_string(uri))

  def init(opts) when is_list(opts),
    do: struct(__MODULE__, req: init_req(opts))

  def init(%Req.Request{} = req),
    do: struct(__MODULE__, req: req)

  @spec init_req(keyword()) :: Req.Request.t()
  defp init_req(opts) do
    api_key = System.get_env("OLLAMA_API_KEY")

    base_url =
      opts
      |> Keyword.get(:base_url, Keyword.get(opts, :host, System.get_env("OLLAMA_HOST")))
      |> normalize_base_url()

    base_headers = [{"user-agent", user_agent()}]

    api_key_headers =
      if api_key do
        [{"authorization", "Bearer #{api_key}"}]
      else
        []
      end

    user_headers = Keyword.get(opts, :headers, [])

    merged_headers = merge_headers(base_headers ++ api_key_headers, user_headers)

    opts
    |> Keyword.drop([:base_url, :host, :headers])
    |> Keyword.put(:base_url, base_url)
    |> Keyword.put(:headers, merged_headers)
    |> Keyword.put_new(:receive_timeout, 60_000)
    |> Req.new()
  end

  defp user_agent do
    arch =
      :erlang.system_info(:system_architecture)
      |> to_string()
      |> String.split("-", parts: 2)
      |> hd()

    os = user_agent_os()

    "ollama-ex/#{@version} (#{arch} #{os}) Elixir/#{System.version()} OTP/#{System.otp_release()}"
  end

  defp user_agent_os do
    case :os.type() do
      {:unix, :darwin} -> "darwin"
      {:unix, :linux} -> "linux"
      {:win32, _} -> "windows"
      {_, name} -> to_string(name)
    end
  end

  defp ensure_api_suffix(url) when is_binary(url) do
    trimmed = String.trim_trailing(url, "/")

    if String.ends_with?(trimmed, "/api") do
      trimmed
    else
      trimmed <> "/api"
    end
  end

  defp normalize_base_url(%URI{} = uri), do: normalize_base_url(URI.to_string(uri))
  defp normalize_base_url(nil), do: ensure_api_suffix(parse_host(nil))

  defp normalize_base_url(url) when is_binary(url) do
    trimmed = String.trim(url)

    if trimmed == "" do
      ensure_api_suffix(parse_host(nil))
    else
      base =
        if String.contains?(trimmed, "://") do
          trimmed
        else
          trimmed
          |> String.trim_trailing("/")
          |> String.split("/", parts: 2)
          |> hd()
          |> parse_host()
        end

      ensure_api_suffix(base)
    end
  end

  defp parse_host(nil), do: "http://localhost:11434"
  defp parse_host(""), do: "http://localhost:11434"

  defp parse_host(host) when is_binary(host) do
    host = String.trim(host)
    host = String.trim_trailing(host, "/")

    cond do
      String.starts_with?(host, "http://") or String.starts_with?(host, "https://") ->
        host

      String.starts_with?(host, ":") ->
        "http://localhost:" <> String.trim_leading(host, ":")

      String.contains?(host, ":") ->
        "http://" <> host

      true ->
        "http://" <> host <> ":11434"
    end
  end

  defp merge_headers(base, override) do
    override_keys = Enum.map(override, fn {k, _} -> String.downcase(to_string(k)) end)

    base
    |> Enum.reject(fn {k, _} -> String.downcase(to_string(k)) in override_keys end)
    |> Kernel.++(override)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp pop_response_format(params) do
    {format, params} = Keyword.pop(params, :response_format)
    {resolve_response_format(format), params}
  end

  defp resolve_response_format(nil) do
    Application.get_env(:ollama, :response_format, :map)
  end

  defp resolve_response_format(format) when format in [:map, :struct], do: format
  defp resolve_response_format(_), do: :map

  defp validate_params(params, schema) do
    case NimbleOptions.validate(params, schema) do
      {:ok, params} ->
        {:ok, params}

      {:error, %NimbleOptions.ValidationError{} = error} ->
        {:error,
         RequestError.exception(
           message: Exception.message(error),
           field: error.key,
           reason: :validation_error
         )}
    end
  end

  defp cast_fun_for(_endpoint, :map), do: nil
  defp cast_fun_for(_endpoint, nil), do: nil
  defp cast_fun_for(:chat, :struct), do: &Ollama.Types.ChatResponse.from_map/1
  defp cast_fun_for(:completion, :struct), do: &Ollama.Types.GenerateResponse.from_map/1
  defp cast_fun_for(:embed, :struct), do: &Ollama.Types.EmbedResponse.from_map/1
  defp cast_fun_for(:embeddings, :struct), do: &Ollama.Types.EmbeddingsResponse.from_map/1
  defp cast_fun_for(:list_models, :struct), do: &Ollama.Types.ListResponse.from_map/1
  defp cast_fun_for(:list_running, :struct), do: &Ollama.Types.ProcessResponse.from_map/1
  defp cast_fun_for(:show_model, :struct), do: &Ollama.Types.ShowResponse.from_map/1
  defp cast_fun_for(:progress, :struct), do: &Ollama.Types.ProgressResponse.from_map/1
  defp cast_fun_for(:status, :struct), do: &Ollama.Types.StatusResponse.from_map/1
  defp cast_fun_for(_endpoint, _format), do: nil

  defp apply_cast({:ok, %Task{} = task}, _cast_fun), do: {:ok, task}

  defp apply_cast({:ok, enum}, cast_fun) when is_function(enum) do
    if is_function(cast_fun) do
      {:ok, Stream.map(enum, cast_fun)}
    else
      {:ok, enum}
    end
  end

  defp apply_cast({:ok, body}, cast_fun) when is_function(cast_fun) do
    {:ok, cast_fun.(body)}
  end

  defp apply_cast(result, _cast_fun), do: result

  defp normalize_options(opts) do
    case Keyword.get(opts, :options) do
      nil ->
        {:ok, opts}

      %Options{} = options ->
        {:ok, Keyword.put(opts, :options, Options.to_map(options))}

      map when is_map(map) ->
        {:ok, opts}

      keyword when is_list(keyword) ->
        case Options.build(keyword) do
          {:ok, options} ->
            {:ok, Keyword.put(opts, :options, Options.to_map(options))}

          {:error, reason} ->
            {:error, RequestError.exception(message: "Invalid options", reason: reason)}
        end

      other ->
        {:error,
         RequestError.invalid_type(:options, other, "map, keyword list, or Ollama.Options")}
    end
  end

  defp normalize_tools(opts) do
    case Keyword.get(opts, :tools) do
      nil ->
        {:ok, opts}

      tools when is_list(tools) ->
        case Tool.prepare(tools) do
          {:ok, prepared} ->
            {:ok, Keyword.put(opts, :tools, prepared)}

          {:error, reason} ->
            {:error, RequestError.exception(message: "Invalid tool", reason: reason)}
        end

      other ->
        {:error, RequestError.invalid_type(:tools, other, "list")}
    end
  end

  defp normalize_images(opts) do
    case Keyword.get(opts, :images) do
      nil ->
        {:ok, opts}

      images when is_list(images) ->
        case Image.encode_all(images) do
          {:ok, encoded} ->
            {:ok, Keyword.put(opts, :images, encoded)}

          {:error, reason} ->
            {:error, RequestError.exception(message: "Image encoding failed", reason: reason)}
        end

      other ->
        {:error, RequestError.invalid_type(:images, other, "list")}
    end
  end

  defp normalize_messages_images(opts) do
    case Keyword.get(opts, :messages) do
      nil ->
        {:ok, opts}

      messages when is_list(messages) ->
        with {:ok, updated} <- encode_message_images(messages) do
          {:ok, Keyword.put(opts, :messages, updated)}
        end

      other ->
        {:error, RequestError.invalid_type(:messages, other, "list")}
    end
  end

  defp encode_message_images(messages) do
    Enum.reduce_while(messages, {:ok, []}, fn message, {:ok, acc} ->
      case encode_message_images_one(message) do
        {:ok, updated} -> {:cont, {:ok, acc ++ [updated]}}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  defp encode_message_images_one(message) when is_map(message) do
    message = if is_struct(message), do: Map.from_struct(message), else: message

    {key, images} =
      cond do
        Map.has_key?(message, :images) -> {:images, Map.get(message, :images)}
        Map.has_key?(message, "images") -> {"images", Map.get(message, "images")}
        true -> {nil, nil}
      end

    cond do
      is_nil(key) ->
        {:ok, drop_nil_values(message)}

      is_nil(images) ->
        {:ok, drop_nil_values(message)}

      is_list(images) ->
        case Image.encode_all(images) do
          {:ok, encoded} ->
            {:ok, drop_nil_values(Map.put(message, key, encoded))}

          {:error, reason} ->
            {:error, RequestError.exception(message: "Image encoding failed", reason: reason)}
        end

      true ->
        {:error, RequestError.invalid_type(:images, images, "list")}
    end
  end

  defp encode_message_images_one(other), do: {:ok, other}

  defp drop_nil_values(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  schema(:chat,
    model: [
      type: :string,
      required: true,
      doc: "The ollama model name."
    ],
    messages: [
      type: {:list, {:map, schema_def(:chat_message).schema}},
      required: true,
      doc: "List of messages - used to keep a chat memory."
    ],
    tools: [
      type: {:list, {:map, schema_def(:tool_def).schema}},
      doc: "Tools for the model to use if supported (requires `stream` to be `false`)"
    ],
    format: [
      type: {:or, [:string, @permissive_map]},
      doc: "Set the expected format of the response (`json` or JSON schema map)."
    ],
    stream: [
      type: {:or, [:boolean, :pid]},
      default: false,
      doc: "See [section on streaming](#module-streaming)."
    ],
    think: [
      type: {:or, [:boolean, {:in, ["low", "medium", "high"]}]},
      default: false,
      doc: "Enable thinking mode. Can be true/false or level: 'low', 'medium', 'high'"
    ],
    logprobs: [
      type: :boolean,
      doc: "Return log probabilities for generated tokens"
    ],
    top_logprobs: [
      type: :integer,
      doc: "Number of alternative tokens to return (0-20)"
    ],
    keep_alive: [
      type: {:or, [:integer, :string]},
      doc: "How long to keep the model loaded."
    ],
    options: [
      type: {:map, {:or, [:atom, :string]}, :any},
      doc:
        "Additional advanced [model parameters](https://github.com/jmorganca/ollama/blob/main/docs/modelfile.md#valid-parameters-and-values)."
    ]
  )

  @doc """
  Generates the next message in a chat using the specified model. Optionally
  streamable.

  ## Parameters

  - `client` - Ollama client from `init/1`
  - `params` - Keyword list of chat options (see below)

  ## Options

  #{doc(:chat)}

  ## Message structure

  Each message is a map with the following fields:

  #{doc(:chat_message)}

  ## Tool definitions

  #{doc(:tool_def)}

  ## Examples

      iex> messages = [
      ...>   %{role: "system", content: "You are a helpful assistant."},
      ...>   %{role: "user", content: "Why is the sky blue?"},
      ...>   %{role: "assistant", content: "Due to rayleigh scattering."},
      ...>   %{role: "user", content: "How is that different than mie scattering?"},
      ...> ]

      iex> Ollama.chat(client, [
      ...>   model: "llama2",
      ...>   messages: messages,
      ...> ])
      {:ok, %{"message" => %{
        "role" => "assistant",
        "content" => "Mie scattering affects all wavelengths similarly, while Rayleigh favors shorter ones."
      }, ...}}

      # Passing true to the :stream option initiates an async streaming request.
      iex> Ollama.chat(client, [
      ...>   model: "llama2",
      ...>   messages: messages,
      ...>   stream: true,
      ...> ])
      {:ok, Ollama.Streaming{}}

  ## Returns

  - `{:ok, map()}` - Success with response data
  - `{:ok, Stream.t()}` - When `stream: true`
  - `{:ok, Task.t()}` - When `stream: pid`
  - `{:error, Ollama.RequestError.t()}` - On validation errors
  - `{:error, Ollama.ResponseError.t()}` - On HTTP errors

  ## See Also

  - `completion/2` - For single-turn generation
  - `embed/2` - For embeddings
  """
  @spec chat(client(), keyword()) :: response()
  def chat(%__MODULE__{} = client, params) when is_list(params) do
    {format, params} = pop_response_format(params)
    cast_fun = cast_fun_for(:chat, format)

    with {:ok, params} <- normalize_options(params),
         {:ok, params} <- normalize_tools(params),
         {:ok, params} <- normalize_messages_images(params),
         {:ok, params} <- validate_params(params, schema_def(:chat)) do
      result =
        client
        |> req(:post, "/chat", json: Enum.into(params, %{}), cast: cast_fun)
        |> res()

      if params[:stream], do: result, else: apply_cast(result, cast_fun)
    end
  end

  schema(:completion,
    model: [
      type: :string,
      required: true,
      doc: "The ollama model name."
    ],
    prompt: [
      type: :string,
      required: true,
      doc: "Prompt to generate a response for."
    ],
    suffix: [
      type: :string,
      doc: "Text to append after generated content (for code completion)"
    ],
    images: [
      type: {:list, :string},
      doc:
        "A list of Base64 encoded images to be included with the prompt (for multimodal models only)."
    ],
    system: [
      type: :string,
      doc: "System prompt, overriding the model default."
    ],
    template: [
      type: :string,
      doc: "Prompt template, overriding the model default."
    ],
    context: [
      type: {:list, {:or, [:integer, :float]}},
      doc:
        "The context parameter returned from a previous `completion/2` call (enabling short conversational memory)."
    ],
    format: [
      type: {:or, [:string, @permissive_map]},
      doc: "Set the expected format of the response (`json` or JSON schema map)."
    ],
    raw: [
      type: :boolean,
      doc: "Set `true` if specifying a fully templated prompt. (`:template` is ingored)"
    ],
    stream: [
      type: {:or, [:boolean, :pid]},
      default: false,
      doc: "See [section on streaming](#module-streaming)."
    ],
    think: [
      type: {:or, [:boolean, {:in, ["low", "medium", "high"]}]},
      default: false,
      doc: "Enable thinking mode. Can be true/false or level: 'low', 'medium', 'high'"
    ],
    logprobs: [
      type: :boolean,
      doc: "Return log probabilities for generated tokens"
    ],
    top_logprobs: [
      type: :integer,
      doc: "Number of alternative tokens to return (0-20)"
    ],
    keep_alive: [
      type: {:or, [:integer, :string]},
      doc: "How long to keep the model loaded."
    ],
    options: [
      type: {:map, {:or, [:atom, :string]}, :any},
      doc:
        "Additional advanced [model parameters](https://github.com/jmorganca/ollama/blob/main/docs/modelfile.md#valid-parameters-and-values)."
    ]
  )

  @doc """
  Generates a completion for the given prompt using the specified model.
  Optionally streamable.

  ## Parameters

  - `client` - Ollama client from `init/1`
  - `params` - Keyword list of completion options (see below)

  ## Options

  #{doc(:completion)}

  ## Examples

      iex> Ollama.completion(client, [
      ...>   model: "llama2",
      ...>   prompt: "Why is the sky blue?",
      ...> ])
      {:ok, %{"response": "The sky is blue because it is the color of the sky.", ...}}

      # Passing true to the :stream option initiates an async streaming request.
      iex> Ollama.completion(client, [
      ...>   model: "llama2",
      ...>   prompt: "Why is the sky blue?",
      ...>   stream: true,
      ...> ])
      {:ok, %Ollama.Streaming{}}

  ## Returns

  - `{:ok, map()}` - Success with response data
  - `{:ok, Stream.t()}` - When `stream: true`
  - `{:ok, Task.t()}` - When `stream: pid`
  - `{:error, Ollama.RequestError.t()}` - On validation errors
  - `{:error, Ollama.ResponseError.t()}` - On HTTP errors

  ## See Also

  - `chat/2` - For multi-turn conversations
  - `embed/2` - For embeddings
  """
  @spec completion(client(), keyword()) :: response()
  def completion(%__MODULE__{} = client, params) when is_list(params) do
    {format, params} = pop_response_format(params)
    cast_fun = cast_fun_for(:completion, format)

    with {:ok, params} <- normalize_options(params),
         {:ok, params} <- normalize_images(params),
         {:ok, params} <- validate_params(params, schema_def(:completion)) do
      result =
        client
        |> req(:post, "/generate", json: Enum.into(params, %{}), cast: cast_fun)
        |> res()

      if params[:stream], do: result, else: apply_cast(result, cast_fun)
    end
  end

  @doc """
  Alias for `completion/2` to match the Python client's `generate`.
  """
  @spec generate(client(), keyword()) :: response()
  def generate(%__MODULE__{} = client, params) when is_list(params) do
    completion(client, params)
  end

  schema(:create_model,
    name: [type: :string, required: true, doc: "Name for the new model"],
    modelfile: [type: :string, doc: "Modelfile contents"],
    from: [type: :string, doc: "Base model to create from"],
    files: [type: {:map, :string, :string}, doc: "Custom files to include"],
    adapters: [type: {:map, :string, :string}, doc: "LoRA adapter files"],
    template: [type: :string, doc: "Custom prompt template"],
    license: [type: {:or, [:string, {:list, :string}]}, doc: "License declaration"],
    system: [type: :string, doc: "System prompt"],
    parameters: [type: {:or, [:map, :keyword_list]}, doc: "Model parameters"],
    messages: [type: {:list, :map}, doc: "Sample conversation messages"],
    quantize: [type: :string, doc: "Quantization level (f16, f32, etc.)"],
    stream: [type: {:or, [:boolean, :pid]}, doc: "Enable streaming"]
  )

  @doc """
  Creates a model using the given name and model file. Optionally
  streamable.

  Any dependent blobs reference in the modelfile, such as `FROM` and `ADAPTER`
  instructions, must exist first. See `check_blob/2` and `create_blob/2`.

  ## Parameters

  - `client` - Ollama client from `init/1`
  - `params` - Keyword list of model creation options (see below)

  ## Options

  #{doc(:create_model)}

  ## Example

      iex> modelfile = "FROM llama2\\nSYSTEM \\"You are mario from Super Mario Bros.\\""
      iex> Ollama.create_model(client, [
      ...>   name: "mario",
      ...>   modelfile: modelfile,
      ...>   stream: true,
      ...> ])
      {:ok, Ollama.Streaming{}}

  ## Returns

  - `{:ok, map()}` - Success with response data
  - `{:ok, Stream.t()}` - When `stream: true`
  - `{:ok, Task.t()}` - When `stream: pid`
  - `{:error, Ollama.RequestError.t()}` - On validation errors
  - `{:error, Ollama.ResponseError.t()}` - On HTTP errors

  ## See Also

  - `check_blob/2` - Verify dependent blobs
  - `create_blob/2` - Create blob dependencies
  """
  @spec create_model(client(), keyword()) :: response()
  def create_model(%__MODULE__{} = client, params) when is_list(params) do
    {format, params} = pop_response_format(params)
    cast_fun = cast_fun_for(:progress, format)

    with {:ok, params} <- normalize_messages_images(params),
         {:ok, params} <- validate_params(params, schema_def(:create_model)) do
      parameters =
        case params[:parameters] do
          list when is_list(list) -> Enum.into(list, %{})
          map -> map
        end

      body =
        %{}
        |> Map.put(:name, params[:name])
        |> maybe_put(:modelfile, params[:modelfile])
        |> maybe_put(:from, params[:from])
        |> maybe_put(:files, params[:files])
        |> maybe_put(:adapters, params[:adapters])
        |> maybe_put(:template, params[:template])
        |> maybe_put(:license, params[:license])
        |> maybe_put(:system, params[:system])
        |> maybe_put(:parameters, parameters)
        |> maybe_put(:messages, params[:messages])
        |> maybe_put(:quantize, params[:quantize])
        |> maybe_put(:stream, params[:stream])

      result =
        client
        |> req(:post, "/create", json: body, cast: cast_fun)
        |> res()

      if params[:stream], do: result, else: apply_cast(result, cast_fun)
    end
  end

  @doc """
  Alias for `create_model/2` to match the Python client's `create`.
  """
  @spec create(client(), keyword()) :: response()
  def create(%__MODULE__{} = client, params) when is_list(params) do
    create_model(client, params)
  end

  @doc """
  Lists all models that Ollama has available.

  ## Parameters

  - `client` - Ollama client from `init/1`

  ## Example

      iex> Ollama.list_models(client)
      {:ok, %{"models" => [
        %{"name" => "codellama:13b", ...},
        %{"name" => "llama2:latest", ...},
      ]}}

  ## Returns

  - `{:ok, map()}` - Map containing available models
  - `{:error, Ollama.ResponseError.t()}` - On HTTP errors

  ## See Also

  - `show_model/2` - Fetch model details
  - `list_running/1` - List running models
  """
  @spec list_models(client(), keyword()) :: response()
  def list_models(%__MODULE__{} = client, opts \\ []) when is_list(opts) do
    {format, _opts} = pop_response_format(opts)
    cast_fun = cast_fun_for(:list_models, format)

    client
    |> req(:get, "/tags")
    |> res()
    |> apply_cast(cast_fun)
  end

  @doc """
  Alias for `list_models/2` to match the Python client's `list`.
  """
  @spec list(client(), keyword()) :: response()
  def list(%__MODULE__{} = client, opts \\ []) when is_list(opts) do
    list_models(client, opts)
  end

  @doc """
  Lists currently running models, their memory footprint, and process details.

  ## Parameters

  - `client` - Ollama client from `init/1`

  ## Example

      iex> Ollama.list_running(client)
      {:ok, %{"models" => [
        %{"name" => "nomic-embed-text:latest", ...},
      ]}}

  ## Returns

  - `{:ok, map()}` - Map containing running models
  - `{:error, Ollama.ResponseError.t()}` - On HTTP errors

  ## See Also

  - `list_models/1` - List available models
  - `show_model/2` - Fetch model details
  """
  @spec list_running(client(), keyword()) :: response()
  def list_running(%__MODULE__{} = client, opts \\ []) when is_list(opts) do
    {format, _opts} = pop_response_format(opts)
    cast_fun = cast_fun_for(:list_running, format)

    client
    |> req(:get, "/ps")
    |> res()
    |> apply_cast(cast_fun)
  end

  @doc """
  Alias for `list_running/2` to match the Python client's `ps`.
  """
  @spec ps(client(), keyword()) :: response()
  def ps(%__MODULE__{} = client, opts \\ []) when is_list(opts) do
    list_running(client, opts)
  end

  schema(:load_model,
    model: [
      type: :string,
      required: true,
      doc: "Name of the model to load."
    ],
    keep_alive: [
      type: {:or, [:integer, :string]},
      doc: "How long to keep the model loaded."
    ]
  )

  @doc """
  Load a model into memory without generating a completion. Optionally specify
  a keep alive value (defaults to 5 minutes, set `-1` to permanently keep alive).

  ## Parameters

  - `client` - Ollama client from `init/1`
  - `params` - Keyword list with `:model` and optional `:keep_alive`

  ## Options

  #{doc(:load_model)}

  ## Example

      iex> Ollama.preload(client, model: "llama3.1", timeout: 3_600_000)
      true

  ## Returns

  - `{:ok, true}` - When the model was loaded
  - `{:ok, false}` - When the model was not found
  - `{:error, Ollama.ResponseError.t()}` - On HTTP errors

  ## See Also

  - `unload/2` - Unload a model
  - `list_running/1` - Check running models
  """
  @spec preload(client(), keyword()) :: response()
  def preload(%__MODULE__{} = client, params) when is_list(params) do
    with {:ok, params} <- validate_params(params, schema_def(:load_model)) do
      client
      |> req(:post, "/generate", json: Enum.into(params, %{}))
      |> res_status()
    end
  end

  @doc """
  Stops a running model and unloads it from memory.

  ## Parameters

  - `client` - Ollama client from `init/1`
  - `params` - Keyword list with `:model`

  ## Options

  - `:model` (`t:String.t/0`) - Required. Name of the model to unload.

  ## Example

      iex> Ollama.preload(client, model: "llama3.1")
      true

  ## Returns

  - `{:ok, true}` - When the model was unloaded
  - `{:ok, false}` - When the model was not found
  - `{:error, Ollama.ResponseError.t()}` - On HTTP errors

  ## See Also

  - `preload/2` - Load a model
  - `list_running/1` - Check running models
  """
  @spec unload(client(), keyword()) :: response()
  def unload(%__MODULE__{} = client, params) when is_list(params) do
    with {:ok, params} <- validate_params(params, schema_def(:load_model)) do
      params = Keyword.put(params, :keep_alive, 0)

      client
      |> req(:post, "/generate", json: Enum.into(params, %{}))
      |> res_status()
    end
  end

  schema(:show_model,
    name: [
      type: :string,
      required: true,
      doc: "Name of the model to show."
    ]
  )

  @doc """
  Shows all information for a specific model.

  ## Parameters

  - `client` - Ollama client from `init/1`
  - `params` - Keyword list with `:name`

  ## Options

  #{doc(:show_model)}

  ## Example

      iex> Ollama.show_model(client, name: "llama2")
      {:ok, %{
        "details" => %{
          "families" => ["llama", "clip"],
          "family" => "llama",
          "format" => "gguf",
          "parameter_size" => "7B",
          "quantization_level" => "Q4_0"
        },
        "modelfile" => "...",
        "parameters" => "...",
        "template" => "..."
      }}

  ## Returns

  - `{:ok, map()}` - Model details
  - `{:error, Ollama.RequestError.t()}` - On validation errors
  - `{:error, Ollama.ResponseError.t()}` - On HTTP errors

  ## See Also

  - `list_models/1` - List available models
  """
  @spec show_model(client(), keyword()) :: response()
  def show_model(%__MODULE__{} = client, params) when is_list(params) do
    {format, params} = pop_response_format(params)
    cast_fun = cast_fun_for(:show_model, format)

    with {:ok, params} <- validate_params(params, schema_def(:show_model)) do
      client
      |> req(:post, "/show", json: Enum.into(params, %{}))
      |> res()
      |> apply_cast(cast_fun)
    end
  end

  @doc """
  Alias for `show_model/2` to match the Python client's `show`.
  """
  @spec show(client(), keyword()) :: response()
  def show(%__MODULE__{} = client, params) when is_list(params) do
    show_model(client, params)
  end

  schema(:copy_model,
    source: [
      type: :string,
      required: true,
      doc: "Name of the model to copy from."
    ],
    destination: [
      type: :string,
      required: true,
      doc: "Name of the model to copy to."
    ]
  )

  @doc """
  Creates a model with another name from an existing model.

  ## Parameters

  - `client` - Ollama client from `init/1`
  - `params` - Keyword list with `:source` and `:destination`

  ## Options

  #{doc(:copy_model)}

  ## Example

      iex> Ollama.copy_model(client, [
      ...>   source: "llama2",
      ...>   destination: "llama2-backup"
      ...> ])
      {:ok, true}

  ## Returns

  - `{:ok, true}` - When the copy succeeded
  - `{:ok, false}` - When the model was not found
  - `{:error, Ollama.RequestError.t()}` - On validation errors
  - `{:error, Ollama.ResponseError.t()}` - On HTTP errors

  ## See Also

  - `delete_model/2` - Delete a model
  - `show_model/2` - Inspect a model
  """
  @spec copy_model(client(), keyword()) :: response()
  def copy_model(%__MODULE__{} = client, params) when is_list(params) do
    {format, params} = pop_response_format(params)
    cast_fun = cast_fun_for(:status, format)

    with {:ok, params} <- validate_params(params, schema_def(:copy_model)) do
      result =
        client
        |> req(:post, "/copy", json: Enum.into(params, %{}))
        |> res_status()

      if format == :struct do
        case result do
          {:ok, true} -> apply_cast({:ok, %{"status" => "success"}}, cast_fun)
          {:ok, false} -> apply_cast({:ok, %{"status" => "error"}}, cast_fun)
          {:error, _} = error -> error
        end
      else
        result
      end
    end
  end

  @doc """
  Alias for `copy_model/2` to match the Python client's `copy`.
  """
  @spec copy(client(), keyword()) :: response()
  def copy(%__MODULE__{} = client, params) when is_list(params) do
    copy_model(client, params)
  end

  schema(:delete_model,
    name: [
      type: :string,
      required: true,
      doc: "Name of the model to delete."
    ]
  )

  @doc """
  Deletes a model and its data.

  ## Parameters

  - `client` - Ollama client from `init/1`
  - `params` - Keyword list with `:name`

  ## Options

  #{doc(:copy_model)}

  ## Example

      iex> Ollama.delete_model(client, name: "llama2")
      {:ok, true}

  ## Returns

  - `{:ok, true}` - When the delete succeeded
  - `{:ok, false}` - When the model was not found
  - `{:error, Ollama.RequestError.t()}` - On validation errors
  - `{:error, Ollama.ResponseError.t()}` - On HTTP errors

  ## See Also

  - `copy_model/2` - Copy a model
  - `show_model/2` - Inspect a model
  """
  @spec delete_model(client(), keyword()) :: response()
  def delete_model(%__MODULE__{} = client, params) when is_list(params) do
    {format, params} = pop_response_format(params)
    cast_fun = cast_fun_for(:status, format)

    with {:ok, params} <- validate_params(params, schema_def(:delete_model)) do
      result =
        client
        |> req(:delete, "/delete", json: Enum.into(params, %{}))
        |> res_status()

      if format == :struct do
        case result do
          {:ok, true} -> apply_cast({:ok, %{"status" => "success"}}, cast_fun)
          {:ok, false} -> apply_cast({:ok, %{"status" => "error"}}, cast_fun)
          {:error, _} = error -> error
        end
      else
        result
      end
    end
  end

  @doc """
  Alias for `delete_model/2` to match the Python client's `delete`.
  """
  @spec delete(client(), keyword()) :: response()
  def delete(%__MODULE__{} = client, params) when is_list(params) do
    delete_model(client, params)
  end

  schema(:pull_model,
    name: [
      type: :string,
      required: true,
      doc: "Name of the model to pull."
    ],
    insecure: [
      type: :boolean,
      doc: "Allow insecure (HTTP) connections."
    ],
    stream: [
      type: {:or, [:boolean, :pid]},
      default: false,
      doc: "See [section on streaming](#module-streaming)."
    ]
  )

  @doc """
  Downloads a model from the ollama library. Optionally streamable.

  ## Parameters

  - `client` - Ollama client from `init/1`
  - `params` - Keyword list with `:name` and optional `:stream`

  ## Options

  #{doc(:pull_model)}

  ## Example

      iex> Ollama.pull_model(client, name: "llama2")
      {:ok, %{"status" => "success"}}

      # Passing true to the :stream option initiates an async streaming request.
      iex> Ollama.pull_model(client, name: "llama2", stream: true)
      {:ok, %Ollama.Streaming{}}

  ## Returns

  - `{:ok, map()}` - Status updates or completion
  - `{:ok, Stream.t()}` - When `stream: true`
  - `{:ok, Task.t()}` - When `stream: pid`
  - `{:error, Ollama.RequestError.t()}` - On validation errors
  - `{:error, Ollama.ResponseError.t()}` - On HTTP errors

  ## See Also

  - `push_model/2` - Upload a model
  """
  @spec pull_model(client(), keyword()) :: response()
  def pull_model(%__MODULE__{} = client, params) when is_list(params) do
    {format, params} = pop_response_format(params)
    cast_fun = cast_fun_for(:progress, format)

    with {:ok, params} <- validate_params(params, schema_def(:pull_model)) do
      result =
        client
        |> req(:post, "/pull", json: Enum.into(params, %{}), cast: cast_fun)
        |> res()

      if params[:stream], do: result, else: apply_cast(result, cast_fun)
    end
  end

  @doc """
  Alias for `pull_model/2` to match the Python client's `pull`.
  """
  @spec pull(client(), keyword()) :: response()
  def pull(%__MODULE__{} = client, params) when is_list(params) do
    pull_model(client, params)
  end

  schema(:push_model,
    name: [
      type: :string,
      required: true,
      doc: "Name of the model to pull."
    ],
    insecure: [
      type: :boolean,
      doc: "Allow insecure (HTTP) connections."
    ],
    stream: [
      type: {:or, [:boolean, :pid]},
      default: false,
      doc: "See [section on streaming](#module-streaming)."
    ]
  )

  @doc """
  Upload a model to a model library. Requires an Ollama account and a public
  key from https://ollama.com/settings/keys. Optionally streamable.

  ## Parameters

  - `client` - Ollama client from `init/1`
  - `params` - Keyword list with `:name` and optional `:stream`

  ## Options

  #{doc(:push_model)}

  ## Example

      iex> Ollama.push_model(client, name: "mattw/pygmalion:latest")
      {:ok, %{"status" => "success"}}

      # Passing true to the :stream option initiates an async streaming request.
      iex> Ollama.push_model(client, name: "mattw/pygmalion:latest", stream: true)
      {:ok, %Ollama.Streaming{}}

  ## Returns

  - `{:ok, map()}` - Status updates or completion
  - `{:ok, Stream.t()}` - When `stream: true`
  - `{:ok, Task.t()}` - When `stream: pid`
  - `{:error, Ollama.RequestError.t()}` - On validation errors
  - `{:error, Ollama.ResponseError.t()}` - On HTTP errors

  ## See Also

  - `pull_model/2` - Download a model
  """
  @spec push_model(client(), keyword()) :: response()
  def push_model(%__MODULE__{} = client, params) when is_list(params) do
    {format, params} = pop_response_format(params)
    cast_fun = cast_fun_for(:progress, format)

    with {:ok, params} <- validate_params(params, schema_def(:push_model)) do
      result =
        client
        |> req(:post, "/push", json: Enum.into(params, %{}), cast: cast_fun)
        |> res()

      if params[:stream], do: result, else: apply_cast(result, cast_fun)
    end
  end

  @doc """
  Alias for `push_model/2` to match the Python client's `push`.
  """
  @spec push(client(), keyword()) :: response()
  def push(%__MODULE__{} = client, params) when is_list(params) do
    push_model(client, params)
  end

  @doc """
  Checks a blob exists in ollama by its digest or binary data.

  ## Parameters

  - `client` - Ollama client from `init/1`
  - `digest_or_blob` - Digest string or raw binary data

  ## Examples

      iex> Ollama.check_blob(client, "sha256:fe938a131f40e6f6d40083c9f0f430a515233eb2edaa6d72eb85c50d64f2300e")
      {:ok, true}

      iex> Ollama.check_blob(client, "this should not exist")
      {:ok, false}

  ## Returns

  - `{:ok, true}` - When the blob exists
  - `{:ok, false}` - When the blob does not exist
  - `{:error, Ollama.RequestError.t()}` - On validation errors
  - `{:error, Ollama.ResponseError.t()}` - On HTTP errors

  ## See Also

  - `create_blob/2` - Create a blob
  """
  @spec check_blob(client(), Blob.digest() | binary()) :: response()
  def check_blob(%__MODULE__{} = client, "sha256:" <> _ = digest),
    do: req(client, :head, "/blobs/#{digest}") |> res_status()

  def check_blob(%__MODULE__{} = client, blob) when is_binary(blob),
    do: check_blob(client, Blob.digest(blob))

  @doc """
  Uploads a blob and returns its digest.

  ## Parameters

  - `client` - Ollama client from `init/1`
  - `blob` - File path or raw binary data

  ## Examples

      iex> Ollama.create_blob(client, "adapter.bin")
      {:ok, "sha256:..."}

      iex> data = File.read!("adapter.bin")
      iex> Ollama.create_blob(client, data)
      {:ok, "sha256:..."}

  ## Returns

  - `{:ok, digest}` - When the blob was created or already exists
  - `{:error, Ollama.RequestError.t()}` - On validation errors
  - `{:error, Ollama.ResponseError.t()}` - On HTTP errors

  ## See Also

  - `check_blob/2` - Verify blob existence
  """
  @spec create_blob(client(), binary()) :: response()
  def create_blob(%__MODULE__{} = client, blob) when is_binary(blob) do
    with {:ok, data} <- read_blob_data(blob) do
      digest = Blob.digest(data)

      client
      |> req(:post, "/blobs/#{digest}", body: data)
      |> res_blob(digest)
    end
  end

  defp read_blob_data(blob) when is_binary(blob) do
    cond do
      File.exists?(blob) ->
        case File.read(blob) do
          {:ok, data} ->
            {:ok, data}

          {:error, reason} ->
            {:error,
             RequestError.exception(
               message: "Failed to read blob file",
               reason: {:file_read_error, reason}
             )}
        end

      path_like?(blob) ->
        {:error,
         RequestError.exception(
           message: "Blob file not found",
           reason: :file_not_found
         )}

      true ->
        {:ok, blob}
    end
  end

  defp path_like?(value) when is_binary(value) do
    String.contains?(value, "/") or String.contains?(value, "\\") or Path.extname(value) != ""
  end

  schema(:embed,
    model: [
      type: :string,
      required: true,
      doc: "The name of the model used to generate the embeddings."
    ],
    input: [
      type: {:or, [:string, {:list, :string}]},
      required: true,
      doc: "Text or list of text to generate embeddings for."
    ],
    truncate: [
      type: :boolean,
      doc: "Truncates the end of each input to fit within context length."
    ],
    dimensions: [
      type: :integer,
      doc: "Output embedding dimensions (model-specific)"
    ],
    keep_alive: [
      type: {:or, [:integer, :string]},
      doc: "How long to keep the model loaded."
    ],
    options: [
      type: {:map, {:or, [:atom, :string]}, :any},
      doc:
        "Additional advanced [model parameters](https://github.com/jmorganca/ollama/blob/main/docs/modelfile.md#valid-parameters-and-values)."
    ]
  )

  @doc """
  Generate embeddings from a model for the given prompt.

  ## Parameters

  - `client` - Ollama client from `init/1`
  - `params` - Keyword list of embed options (see below)

  ## Options

  #{doc(:embed)}

  ## Example

      iex> Ollama.embed(client, [
      ...>   model: "nomic-embed-text",
      ...>   input: ["Why is the sky blue?", "Why is the grass green?"],
      ...> ])
      {:ok, %{"embedding" => [
        [ 0.009724553, 0.04449892, -0.14063916, 0.0013168337, 0.032128844,
          0.10730086, -0.008447222, 0.010106917, 5.2289694e-4, -0.03554127, ...],
        [ 0.028196355, 0.043162502, -0.18592504, 0.035034444, 0.055619627,
          0.12082449, -0.0090096295, 0.047170386, -0.032078084, 0.0047163847, ...]
      ]}}

  ## Returns

  - `{:ok, map()}` - Embedding response data
  - `{:error, Ollama.RequestError.t()}` - On validation errors
  - `{:error, Ollama.ResponseError.t()}` - On HTTP errors

  ## See Also

  - `embeddings/2` - Deprecated embedding API
  """
  @spec embed(client(), keyword()) :: response()
  def embed(%__MODULE__{} = client, params) when is_list(params) do
    {format, params} = pop_response_format(params)
    cast_fun = cast_fun_for(:embed, format)

    with {:ok, params} <- normalize_options(params),
         {:ok, params} <- validate_params(params, schema_def(:embed)) do
      client
      |> req(:post, "/embed", json: Enum.into(params, %{}))
      |> res()
      |> apply_cast(cast_fun)
    end
  end

  schema(:embeddings,
    model: [
      type: :string,
      required: true,
      doc: "The name of the model used to generate the embeddings."
    ],
    prompt: [
      type: :string,
      required: true,
      doc: "The prompt used to generate the embedding."
    ],
    keep_alive: [
      type: {:or, [:integer, :string]},
      doc: "How long to keep the model loaded."
    ],
    options: [
      type: {:map, {:or, [:atom, :string]}, :any},
      doc:
        "Additional advanced [model parameters](https://github.com/jmorganca/ollama/blob/main/docs/modelfile.md#valid-parameters-and-values)."
    ]
  )

  @doc """
  Generate embeddings from a model for the given prompt.

  ## Parameters

  - `client` - Ollama client from `init/1`
  - `params` - Keyword list of embedding options (see below)

  ## Options

  #{doc(:embeddings)}

  ## Example

      iex> Ollama.embeddings(client, [
      ...>   model: "llama2",
      ...>   prompt: "Here is an article about llamas..."
      ...> ])
      {:ok, %{"embedding" => [
        0.5670403838157654, 0.009260174818336964, 0.23178744316101074, -0.2916173040866852, -0.8924556970596313,
        0.8785552978515625, -0.34576427936553955, 0.5742510557174683, -0.04222835972905159, -0.137906014919281
      ]}}

  ## Returns

  - `{:ok, map()}` - Embedding response data
  - `{:error, Ollama.RequestError.t()}` - On validation errors
  - `{:error, Ollama.ResponseError.t()}` - On HTTP errors

  ## See Also

  - `embed/2` - Preferred embedding API
  """
  @deprecated "Superseded by embed/2"
  @spec embeddings(client(), keyword()) :: response()
  def embeddings(%__MODULE__{} = client, params) when is_list(params) do
    {format, params} = pop_response_format(params)
    cast_fun = cast_fun_for(:embeddings, format)

    with {:ok, params} <- normalize_options(params),
         {:ok, params} <- validate_params(params, schema_def(:embeddings)) do
      client
      |> req(:post, "/embeddings", json: Enum.into(params, %{}))
      |> res()
      |> apply_cast(cast_fun)
    end
  end

  @doc """
  Search the web using Ollama's cloud search API.

  Delegates to `Ollama.Web.search/2`.
  """
  @spec web_search(client(), keyword()) :: response()
  def web_search(%__MODULE__{} = client, params) when is_list(params) do
    Web.search(client, params)
  end

  @doc """
  Search the web using Ollama's cloud search API, raising on error.

  Delegates to `Ollama.Web.search!/2`.
  """
  @spec web_search!(client(), keyword()) :: Web.SearchResponse.t()
  def web_search!(%__MODULE__{} = client, params) when is_list(params) do
    Web.search!(client, params)
  end

  @doc """
  Fetch content from a URL using Ollama's cloud fetch API.

  Delegates to `Ollama.Web.fetch/2`.
  """
  @spec web_fetch(client(), keyword()) :: response()
  def web_fetch(%__MODULE__{} = client, params) when is_list(params) do
    Web.fetch(client, params)
  end

  @doc """
  Fetch content from a URL using Ollama's cloud fetch API, raising on error.

  Delegates to `Ollama.Web.fetch!/2`.
  """
  @spec web_fetch!(client(), keyword()) :: Web.FetchResponse.t()
  def web_fetch!(%__MODULE__{} = client, params) when is_list(params) do
    Web.fetch!(client, params)
  end

  @doc false
  def __schemas__, do: @schemas

  # Builds the request from the given params
  @spec req(client(), atom(), Req.url(), keyword()) :: req_response()
  defp req(%__MODULE__{req: req}, method, url, opts \\ []) do
    {cast_fun, opts} = Keyword.pop(opts, :cast)
    opts = Keyword.merge(opts, method: method, url: normalize_url(url))
    stream_opt = get_in(opts, [:json, :stream])
    dest = if is_pid(stream_opt), do: stream_opt, else: self()

    cond do
      stream_opt ->
        opts =
          opts
          |> Keyword.update!(:json, &Map.put(&1, :stream, true))
          |> Keyword.put(:into, stream_handler(dest, cast_fun))

        task = Task.async(fn -> req |> Req.request(opts) |> res() end)

        case stream_opt do
          true -> {:ok, Stream.resource(fn -> task end, &stream_next/1, &stream_end/1)}
          _ -> {:ok, task}
        end

      Keyword.get(opts, :json) |> is_map() ->
        opts = Keyword.update!(opts, :json, &Map.put(&1, :stream, false))
        Req.request(req, opts)

      true ->
        Req.request(req, opts)
    end
  end

  defp normalize_url(url) when is_binary(url), do: String.trim_leading(url, "/")
  defp normalize_url(url), do: url

  # Normalizes the response returned from the request
  @spec res(req_response()) :: response()
  defp res({:ok, %Task{} = task}), do: {:ok, task}
  defp res({:ok, enum}) when is_function(enum), do: {:ok, enum}

  defp res({:ok, %{status: status, body: body}}) when status in 200..299 do
    {:ok, body}
  end

  defp res({:ok, %{status: status, body: body}}) do
    {:error, ResponseError.exception(status: status, body: body)}
  end

  defp res({:ok, %{status: status}}) do
    {:error, ResponseError.exception(status)}
  end

  defp res({:error, %Req.TransportError{} = error}) do
    {:error, ConnectionError.exception(original_error: error)}
  end

  defp res({:error, error}) do
    {:error, RequestError.exception(inspect(error))}
  end

  # Normalizes blob uploads, returning the digest on success.
  @spec res_blob(req_response(), binary()) :: response()
  defp res_blob({:ok, %{status: status}}, digest) when status in 200..299, do: {:ok, digest}

  defp res_blob({:ok, %{status: status, body: body}}, _digest),
    do: {:error, ResponseError.exception(status: status, body: body)}

  defp res_blob({:ok, %{status: status}}, _digest), do: {:error, ResponseError.exception(status)}

  defp res_blob({:error, %Req.TransportError{} = error}, _digest) do
    {:error, ConnectionError.exception(original_error: error)}
  end

  defp res_blob({:error, error}, _digest), do: {:error, RequestError.exception(inspect(error))}

  # Normalizes status-only responses without raising on HTTP errors.
  @spec res_status(req_response()) :: response()
  defp res_status({:ok, %{status: status}}) when status in 200..299, do: {:ok, true}
  defp res_status({:ok, %{status: _status}}), do: {:ok, false}

  defp res_status({:error, %Req.TransportError{} = error}) do
    {:error, ConnectionError.exception(original_error: error)}
  end

  defp res_status({:error, error}), do: {:error, RequestError.exception(inspect(error))}

  # Returns a callback to handle streaming responses
  @spec stream_handler(pid(), function() | nil) :: fun()
  defp stream_handler(pid, cast_fun) do
    fn {:data, data}, {req, res} ->
      with {:ok, data} <- Jason.decode(data) do
        payload = if is_function(cast_fun), do: cast_fun.(data), else: data
        Process.send(pid, {self(), {:data, payload}}, [])
        {:cont, {req, stream_merge(res, data)}}
      else
        _ -> {:cont, {req, res}}
      end
    end
  end

  # Conditionally merges streaming responses for chat and completion endpoints
  @spec stream_merge(Req.Response.t(), map()) :: Req.Response.t()
  defp stream_merge(%Req.Response{body: body} = res, %{"done" => _} = data)
       when is_map(body) do
    update_in(res.body, fn body ->
      Map.merge(body, data, fn
        "response", prev, next ->
          prev <> next

        "message", prev, next ->
          acc = update_in(prev, ["content"], &(&1 <> next["content"]))

          if Map.has_key?(prev, "thinking") and Map.has_key?(next, "thinking") do
            update_in(acc, ["thinking"], &(&1 <> next["thinking"]))
          else
            acc
          end

        # Enum.reduce(["content", "thinking"], prev, fn key, acc ->
        #  update_in(acc, [key], & &1 <> Map.get(next, key, ""))
        # end)
        _key, _prev, next ->
          next
      end)
    end)
  end

  defp stream_merge(res, data), do: put_in(res.body, data)

  # Recieve messages into a stream
  defp stream_next(%Task{pid: pid, ref: ref} = task) do
    receive do
      {^pid, {:data, data}} ->
        {[data], task}

      {^ref, {:ok, %{}}} ->
        {:halt, task}

      {^ref, {:error, error}} ->
        raise error

      {:DOWN, _ref, _, _pid, _reason} ->
        {:halt, task}
    after
      30_000 -> {:halt, task}
    end
  end

  # Tidy up when the streaming request is finished
  defp stream_end(%Task{ref: ref}), do: Process.demonitor(ref, [:flush])
end
