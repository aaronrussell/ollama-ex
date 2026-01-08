# Web Search Example (Cloud API)
# Run with: elixir examples/web/web_search.exs

root = Path.expand("../..", __DIR__)

ollama_dep =
  if File.exists?(Path.join(root, "mix.exs")) do
    {:ollama, path: root}
  else
    {:ollama, "~> 0.10.0"}
  end

Mix.install([ollama_dep])

client = Ollama.init()

if System.get_env("OLLAMA_API_KEY") in [nil, ""] do
  IO.puts("""
  Skipping web search. Set OLLAMA_API_KEY to run this example.

  1) Create an account at https://ollama.com
  2) Generate a key at https://ollama.com/settings/keys
  3) export OLLAMA_API_KEY="your_key_here"
  """)

  System.halt(0)
end

case Ollama.web_search(client, query: "Elixir language release notes", max_results: 3) do
  {:ok, response} ->
    IO.puts("Results:")

    for result <- response.results do
      IO.puts("- #{result.title} (#{result.url})")
    end

  {:error, error} when is_struct(error, Ollama.ResponseError) and error.status in [401, 403] ->
    IO.puts("""
    Web search failed: #{Exception.message(error)}

    The API key appears to be invalid. Create a new key:
    https://ollama.com/settings/keys
    """)

  {:error, error} ->
    IO.puts("Web search failed: #{inspect(error)}")
end
