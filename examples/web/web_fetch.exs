# Web Fetch Example (Cloud API)
# Run with: elixir examples/web/web_fetch.exs

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
  Skipping web fetch. Set OLLAMA_API_KEY to run this example.

  1) Create an account at https://ollama.com
  2) Generate a key at https://ollama.com/settings/keys
  3) export OLLAMA_API_KEY="your_key_here"
  """)

  System.halt(0)
end

case Ollama.web_fetch(client, url: "https://elixir-lang.org") do
  {:ok, page} ->
    IO.puts("Title: #{page.title}")
    IO.puts("Content preview: #{String.slice(page.content || "", 0, 200)}...")

  {:error, error} when is_struct(error, Ollama.ResponseError) and error.status in [401, 403] ->
    IO.puts("""
    Web fetch failed: #{Exception.message(error)}

    The API key appears to be invalid. Create a new key:
    https://ollama.com/settings/keys
    """)

  {:error, error} ->
    IO.puts("Web fetch failed: #{inspect(error)}")
end
