defmodule Ollama.Schemas do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      Module.register_attribute(__MODULE__, :schemas, accumulate: true, persist: true)
      import Ollama.Schemas
    end
  end

  @doc """
  Returns documentation for the given schema.

  ## Parameters

  - `key` - Schema key

  ## Examples

      Ollama.Schemas.doc(:chat)

  ## Returns

  - `t:Macro.t/0` - Compiled documentation string

  ## See Also

  - `schema_def/1` - Fetch schema definitions
  """
  @spec doc(atom()) :: Macro.t()
  defmacro doc(key) do
    quote do
      @schemas
      |> Keyword.get(unquote(key))
      |> NimbleOptions.docs()
      |> String.replace("\n\n", "\n")
    end
  end

  @doc """
  Registers a schema using the specified key and options.

  ## Parameters

  - `key` - Schema key
  - `opts` - NimbleOptions schema definition

  ## Examples

      schema(:chat, model: [type: :string, required: true])

  ## Returns

  - `t:Macro.t/0` - Macro expansion

  ## See Also

  - `schema_def/1` - Fetch schema definitions
  """
  @spec schema(atom(), NimbleOptions.schema()) :: Macro.t()
  defmacro schema(key, opts) do
    quote do
      @schemas {unquote(key), NimbleOptions.new!(unquote(opts))}
    end
  end

  @doc """
  Fetches a schema by the given key at compile time.

  ## Parameters

  - `key` - Schema key

  ## Examples

      schema_def(:chat)

  ## Returns

  - `t:Macro.t/0` - Schema definition

  ## See Also

  - `schema/1` - Runtime schema lookup
  """
  @spec schema_def(atom()) :: Macro.t()
  defmacro schema_def(key) do
    quote do
      Keyword.fetch!(@schemas, unquote(key))
    end
  end

  @doc """
  Fetches a schema from the compiled Ollama module at runtime.

  ## Parameters

  - `key` - Schema key

  ## Examples

      Ollama.Schemas.schema(:chat)

  ## Returns

  - `t:NimbleOptions.t/0` - Schema definition

  ## See Also

  - `doc/1` - Schema documentation
  """
  @spec schema(atom()) :: NimbleOptions.t()
  def schema(key) do
    Ollama.__schemas__() |> Keyword.fetch!(key)
  end
end
