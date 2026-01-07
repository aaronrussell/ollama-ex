# JSON Schema Structured Output
Mix.install([{:ollama, "~> 0.9"}, {:jason, "~> 1.4"}])

client = Ollama.init()

country_schema = %{
  type: "object",
  properties: %{
    name: %{type: "string"},
    capital: %{type: "string"},
    population: %{type: "integer"},
    languages: %{type: "array", items: %{type: "string"}},
    continent: %{type: "string"}
  },
  required: ["name", "capital", "population", "languages", "continent"]
}

{:ok, response} =
  Ollama.chat(client,
    model: "llama3.2",
    messages: [%{role: "user", content: "Tell me about Japan"}],
    format: country_schema
  )

json_content = response["message"]["content"]
{:ok, country} = Jason.decode(json_content)

IO.inspect(country, label: "Structured Country Data")
