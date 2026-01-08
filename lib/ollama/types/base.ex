defmodule Ollama.Types.Base do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      @behaviour Access

      @impl Access
      def fetch(struct, key) when is_atom(key) do
        Map.fetch(struct, key)
      end

      def fetch(struct, key) when is_binary(key) do
        atom_key = String.to_existing_atom(key)
        Map.fetch(struct, atom_key)
      rescue
        ArgumentError -> :error
      end

      @impl Access
      def get_and_update(struct, key, fun) when is_atom(key) do
        Map.get_and_update(struct, key, fun)
      end

      @impl Access
      def pop(struct, key) when is_atom(key) do
        Map.pop(struct, key)
      end

      defoverridable fetch: 2, get_and_update: 3, pop: 2
    end
  end
end
