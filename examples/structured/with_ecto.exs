# Structured Output with Ecto Validation
# Run with: elixir examples/structured/with_ecto.exs

root = Path.expand("../..", __DIR__)

ollama_dep =
  if File.exists?(Path.join(root, "mix.exs")) do
    {:ollama, path: root}
  else
    {:ollama, "~> 0.10.0"}
  end

Mix.install([ollama_dep, {:ecto, "~> 3.10"}])

defmodule Person do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:name, :string)
    field(:age, :integer)
    field(:occupation, :string)
  end

  def changeset(person, attrs) do
    person
    |> cast(attrs, [:name, :age, :occupation])
    |> validate_required([:name, :age])
    |> validate_number(:age, greater_than: 0, less_than: 150)
  end

  def json_schema do
    %{
      type: "object",
      properties: %{
        name: %{type: "string"},
        age: %{type: "integer"},
        occupation: %{type: "string"}
      },
      required: ["name", "age", "occupation"]
    }
  end
end

client = Ollama.init()

{:ok, response} =
  Ollama.chat(client,
    model: "llama3.2",
    messages: [%{role: "user", content: "Generate a fictional person profile."}],
    format: Person.json_schema()
  )

case Jason.decode(response["message"]["content"]) do
  {:ok, attrs} ->
    changeset = Person.changeset(struct(Person), attrs)

    if changeset.valid? do
      person = Ecto.Changeset.apply_changes(changeset)
      IO.inspect(person, label: "Valid Person")
    else
      IO.inspect(changeset.errors, label: "Validation Errors")
    end

  {:error, reason} ->
    IO.puts("Failed to parse JSON: #{inspect(reason)}")
end
