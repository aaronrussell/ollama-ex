# Structured Outputs

Force the model to return JSON matching a specific schema.

The `:format` option accepts either `"json"` or a JSON Schema map.

## Basic JSON Output

```elixir
{:ok, response} = Ollama.chat(client,
  model: "llama3.2",
  messages: [%{role: "user", content: "Generate a random person"}],
  format: "json"
)

case Jason.decode(response["message"]["content"]) do
  {:ok, data} -> data
  {:error, _} -> raise "Model returned invalid JSON"
end
```

## JSON Schema

For guaranteed structure, provide a JSON Schema:

```elixir
person_schema = %{
  type: "object",
  properties: %{
    name: %{type: "string"},
    age: %{type: "integer"},
    email: %{type: "string", format: "email"}
  },
  required: ["name", "age"]
}

{:ok, response} = Ollama.chat(client,
  model: "llama3.2",
  messages: [%{role: "user", content: "Generate a fictional person"}],
  format: person_schema
)
```

Models can still return invalid JSON. Always validate and handle errors.

## Typed Responses (Optional)

You can request typed response structs with `response_format: :struct` while
still parsing the JSON content from `message` or `response`:

```elixir
{:ok, response} = Ollama.chat(client,
  model: "llama3.2",
  messages: [%{role: "user", content: "Generate a random person"}],
  format: "json",
  response_format: :struct
)

json = response.message.content
{:ok, data} = Jason.decode(json)
```

## With Ecto Schemas

Generate schema from Ecto:

```elixir
defmodule Person do
  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field :name, :string
    field :age, :integer
  end

  def json_schema do
    %{
      type: "object",
      properties: %{
        name: %{type: "string"},
        age: %{type: "integer"}
      },
      required: ["name", "age"]
    }
  end
end
```

## Validation Pattern

```elixir
with {:ok, response} <- Ollama.chat(client, opts),
     {:ok, json} <- Jason.decode(response["message"]["content"]),
     changeset <- Person.changeset(%Person{}, json),
     true <- changeset.valid? do
  {:ok, Ecto.Changeset.apply_changes(changeset)}
else
  {:error, _} = error -> error
  false -> {:error, :validation_failed}
end
```
