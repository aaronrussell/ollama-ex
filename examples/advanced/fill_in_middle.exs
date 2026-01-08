# Fill-in-Middle (FIM) Example
# Run with: elixir examples/advanced/fill_in_middle.exs

root = Path.expand("../..", __DIR__)

ollama_dep =
  if File.exists?(Path.join(root, "mix.exs")) do
    {:ollama, path: root}
  else
    {:ollama, "~> 0.10.0"}
  end

if Code.ensure_loaded?(Mix.Project) &&
     function_exported?(Mix.Project, :get, 0) &&
     Process.whereis(Mix.ProjectStack) &&
     Mix.Project.get() do
  :ok
else
  Mix.install([ollama_dep])
end

client = Ollama.init()
model = System.get_env("OLLAMA_FIM_MODEL", "codellama:7b-code")

prefix = """
def remove_non_ascii(s: str) -> str:
    \"\"\"Remove non-ASCII characters from a string.\"\"\"
    return "".join([
"""

suffix = "    ])\n"

case Ollama.completion(client,
       model: model,
       prompt: prefix,
       suffix: suffix,
       options: [
         num_predict: 128,
         temperature: 0,
         top_p: 0.9,
         stop: ["<EOT>", "\n\ndef ", "\n\nclass "]
       ]
     ) do
  {:ok, response} ->
    middle = response["response"] |> String.trim_trailing()
    IO.puts("Generated middle:\n#{middle}")
    IO.puts("\nFull result:\n")
    IO.puts(prefix <> middle <> "\n" <> suffix)

  {:error, error} when is_struct(error, Ollama.ResponseError) ->
    reason = error.error || error.message || ""

    cond do
      error.status == 404 ->
        IO.puts("Model #{model} not found. Install with: ollama pull #{model}")

      String.contains?(to_string(reason), "does not support insert") ->
        IO.puts("FIM not supported by #{model}. Try OLLAMA_FIM_MODEL=codellama:7b-code.")

      true ->
        IO.puts("FIM request failed for #{model}.")
    end

    IO.puts("Error: #{Exception.message(error)}")

  {:error, error} ->
    IO.puts("Error: #{inspect(error)}")
end
