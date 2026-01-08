defmodule Ollama.Tool do
  @moduledoc """
  Tool definition helpers for function calling.

  Provides utilities to define tools declaratively and convert
  Elixir functions to tool definitions.
  """

  @type param_type :: :string | :integer | :number | :boolean | :array | :object
  @type param_opts :: [
          type: param_type(),
          required: boolean(),
          description: String.t(),
          enum: [any()],
          default: any(),
          items: param_opts()
        ]

  @type tool_def :: %{
          type: String.t(),
          function: %{
            name: String.t(),
            description: String.t() | nil,
            parameters: map()
          }
        }

  @doc """
  Define a tool with a name, description, and parameters.
  """
  @spec define(atom() | String.t(), keyword()) :: tool_def()
  def define(name, opts) do
    name = to_string(name)
    description = Keyword.fetch!(opts, :description)
    params = Keyword.get(opts, :parameters, [])

    %{
      type: "function",
      function: %{
        name: name,
        description: description,
        parameters: build_parameters(params)
      }
    }
  end

  @doc """
  Create a tool definition from a function reference.
  """
  @spec from_function(function()) :: {:ok, tool_def()} | {:error, term()}
  def from_function(fun) when is_function(fun) do
    info = Function.info(fun)

    if Keyword.get(info, :type) == :external do
      module = Keyword.get(info, :module)
      name = Keyword.get(info, :name)
      arity = Keyword.get(info, :arity)

      if module && name && arity do
        from_mfa(module, name, arity)
      else
        {:error, :anonymous_function}
      end
    else
      {:error, :anonymous_function}
    end
  end

  @doc """
  Create a tool definition from module, function name, and arity.
  """
  @spec from_mfa(module(), atom(), non_neg_integer()) :: {:ok, tool_def()} | {:error, term()}
  def from_mfa(module, function, arity) do
    with {:ok, doc} <- get_function_doc(module, function, arity),
         {:ok, spec} <- get_function_spec(module, function, arity),
         {:ok, params} <- spec_to_parameters(spec, doc, arity) do
      function_def =
        %{
          name: to_string(function),
          parameters: params
        }
        |> maybe_put(:description, doc.description)

      {:ok,
       %{
         type: "function",
         function: function_def
       }}
    end
  end

  @doc """
  Convert a list that may contain functions to tool definitions.
  """
  @spec prepare([function() | tool_def()]) :: {:ok, [tool_def()]} | {:error, term()}
  def prepare(tools) when is_list(tools) do
    Enum.reduce_while(tools, {:ok, []}, fn tool, {:ok, acc} ->
      case convert_if_function(tool) do
        {:ok, converted} -> {:cont, {:ok, acc ++ [converted]}}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  @doc """
  Same as prepare/1 but raises on error.
  """
  @spec prepare!([function() | tool_def()]) :: [tool_def()]
  def prepare!(tools) do
    case prepare(tools) do
      {:ok, result} -> result
      {:error, reason} -> raise ArgumentError, "Failed to prepare tools: #{inspect(reason)}"
    end
  end

  defp convert_if_function(fun) when is_function(fun), do: from_function(fun)
  defp convert_if_function(tool) when is_map(tool), do: {:ok, tool}
  defp convert_if_function(other), do: {:error, {:invalid_tool, other}}

  defp build_parameters(params) do
    {properties, required} =
      Enum.reduce(params, {%{}, []}, fn {name, opts}, {props, req} ->
        prop = build_property(opts)
        props = Map.put(props, to_string(name), prop)

        req =
          if Keyword.get(opts, :required, false) and not Keyword.has_key?(opts, :default) do
            req ++ [to_string(name)]
          else
            req
          end

        {props, req}
      end)

    %{
      type: "object",
      properties: properties,
      required: required
    }
  end

  defp build_property(opts) when is_list(opts) do
    type = Keyword.get(opts, :type, :string)

    prop = %{type: type_to_json_schema(type)}

    prop =
      if desc = Keyword.get(opts, :description) do
        Map.put(prop, :description, desc)
      else
        prop
      end

    prop =
      if enum = Keyword.get(opts, :enum) do
        Map.put(prop, :enum, enum)
      else
        prop
      end

    items = Keyword.get(opts, :items)

    prop =
      if type == :array and items do
        Map.put(prop, :items, build_property(items))
      else
        prop
      end

    prop
  end

  defp build_property(opts) when is_map(opts) do
    opts
    |> Enum.map(fn {k, v} -> {k, v} end)
    |> build_property()
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp type_to_json_schema(:string), do: "string"
  defp type_to_json_schema(:integer), do: "integer"
  defp type_to_json_schema(:number), do: "number"
  defp type_to_json_schema(:boolean), do: "boolean"
  defp type_to_json_schema(:array), do: "array"
  defp type_to_json_schema(:object), do: "object"
  defp type_to_json_schema(other), do: to_string(other)

  defp get_function_doc(module, function, arity) do
    case Code.fetch_docs(module) do
      {:docs_v1, _, _, _, _, _, docs} ->
        doc =
          Enum.find_value(docs, fn
            {{:function, ^function, ^arity}, _, _, %{"en" => doc}, _} -> doc
            {{:function, ^function, ^arity}, _, _, doc, _} when is_binary(doc) -> doc
            _ -> nil
          end)

        if doc do
          {:ok, parse_doc(doc)}
        else
          {:ok, %{description: nil, params: %{}, params_order: []}}
        end

      _ ->
        {:ok, %{description: nil, params: %{}, params_order: []}}
    end
  end

  defp parse_doc(doc) do
    lines = String.split(doc, "\n")

    description =
      lines
      |> Enum.take_while(&(!String.starts_with?(&1, "##")))
      |> Enum.join(" ")
      |> String.trim()

    {param_docs, param_order} = extract_param_docs(lines)

    %{description: description, params: param_docs, params_order: param_order}
  end

  defp extract_param_docs(lines) do
    regex = ~r/^\s*[-*]\s*`?(\w+)`?\s*-\s*(.+)/

    {_, acc, order} =
      Enum.reduce(lines, {:scanning, %{}, []}, fn line, {state, acc, order} ->
        cond do
          String.match?(line, ~r/^##\s*(Parameters|Args|Arguments)/i) ->
            {:in_params, acc, order}

          state == :in_params and Regex.match?(regex, line) ->
            [_, name, desc] = Regex.run(regex, line)
            {:in_params, Map.put(acc, name, String.trim(desc)), order ++ [name]}

          state == :in_params and String.starts_with?(line, "##") ->
            {:done, acc, order}

          true ->
            {state, acc, order}
        end
      end)

    {acc, order}
  end

  defp get_function_spec(module, function, arity) do
    case Code.Typespec.fetch_specs(module) do
      {:ok, specs} ->
        spec =
          Enum.find_value(specs, fn
            {{^function, ^arity}, spec} -> spec
            _ -> nil
          end)

        {:ok, spec}

      :error ->
        {:ok, nil}
    end
  end

  defp spec_to_parameters(nil, doc, arity) when is_integer(arity) and arity >= 0 do
    names =
      case doc.params_order do
        [] ->
          Enum.map(1..arity, &"arg#{&1}")

        order when length(order) < arity ->
          order ++ Enum.map((length(order) + 1)..arity, &"arg#{&1}")

        order ->
          Enum.take(order, arity)
      end

    {properties, required} =
      Enum.reduce(names, {%{}, []}, fn name, {props, req} ->
        desc = Map.get(doc.params, name, "")
        prop = %{type: "string"}
        prop = if desc != "", do: Map.put(prop, :description, desc), else: prop
        {Map.put(props, name, prop), req ++ [name]}
      end)

    {:ok, %{type: "object", properties: properties, required: required}}
  end

  defp spec_to_parameters([{:type, _, :fun, [{:type, _, :product, args}, _return]}], doc, _arity) do
    {properties, required} =
      args
      |> Enum.with_index()
      |> Enum.reduce({%{}, []}, fn {arg_type, idx}, {props, req} ->
        {name, type_ast} = arg_name_and_type(arg_type, idx, doc.params_order)
        json_type = typespec_to_json_type(type_ast)
        desc = Map.get(doc.params, name, "")

        prop = %{type: json_type}
        prop = if desc != "", do: Map.put(prop, :description, desc), else: prop

        {Map.put(props, name, prop), req ++ [name]}
      end)

    {:ok, %{type: "object", properties: properties, required: required}}
  end

  defp spec_to_parameters(_, _doc, _arity), do: {:error, :complex_spec}

  defp arg_name_and_type({:ann_type, _, [{:var, _, name}, type]}, _idx, _order) do
    {Atom.to_string(name), type}
  end

  defp arg_name_and_type(type, idx, order) when is_list(order) do
    case Enum.at(order, idx) do
      nil -> {"arg#{idx + 1}", type}
      name -> {name, type}
    end
  end

  defp typespec_to_json_type({:type, _, :integer, _}), do: "integer"
  defp typespec_to_json_type({:type, _, :float, _}), do: "number"
  defp typespec_to_json_type({:type, _, :number, _}), do: "number"
  defp typespec_to_json_type({:type, _, :binary, _}), do: "string"
  defp typespec_to_json_type({:type, _, :boolean, _}), do: "boolean"
  defp typespec_to_json_type({:type, _, :list, _}), do: "array"
  defp typespec_to_json_type({:type, _, :map, _}), do: "object"

  defp typespec_to_json_type({:remote_type, _, [{:atom, _, String}, {:atom, _, :t}, _]}),
    do: "string"

  defp typespec_to_json_type(_), do: "string"
end
