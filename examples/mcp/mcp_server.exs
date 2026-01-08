# MCP Web Tools Server Example
# Run with: elixir examples/mcp/mcp_server.exs
#
# This is a minimal JSON-RPC stdio server that exposes Ollama's web_search
# and web_fetch endpoints as MCP tools. It expects MCP clients to speak
# JSON-RPC 2.0 with methods `tools/list` and `tools/call`.
#
# Works with any MCP client that supports stdio (Cursor, Claude Desktop,
# Cline, Continue, Open WebUI).
#
# Example MCP config:
#
# {
#   "mcpServers": {
#     "ollama_web": {
#       "type": "stdio",
#       "command": "elixir",
#       "args": ["examples/mcp/mcp_server.exs"]
#     }
#   }
# }
#
# Requires OLLAMA_API_KEY for hosted web requests.

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

defmodule OllamaMCP.Server do
  def start(client) do
    IO.puts(:stderr, "Starting Ollama MCP server (stdio)...")
    IO.puts(:stderr, "Waiting for JSON-RPC requests on stdin.")
    loop(client)
  end

  defp loop(client) do
    case IO.read(:stdio, :line) do
      :eof ->
        :ok

      {:error, _} ->
        :ok

      line ->
        line
        |> String.trim()
        |> handle_line(client)

        loop(client)
    end
  end

  defp handle_line("", _client), do: :ok

  defp handle_line(line, client) do
    case Jason.decode(line) do
      {:ok, payload} ->
        dispatch(payload, client)

      {:error, error} ->
        respond_error(nil, "Invalid JSON: #{Exception.message(error)}")
    end
  end

  defp dispatch(%{"method" => "tools/list", "id" => id}, _client) do
    respond(id, %{"tools" => tools()})
  end

  defp dispatch(%{"method" => "tools/call", "id" => id, "params" => params}, client) do
    case call_tool(params, client) do
      {:ok, result} -> respond(id, result)
      {:error, message} -> respond_error(id, message)
    end
  end

  defp dispatch(%{"id" => id}, _client) do
    respond_error(id, "Unsupported method")
  end

  defp call_tool(%{"name" => "web_search", "arguments" => args}, client) do
    query = Map.get(args, "query")
    max_results = Map.get(args, "max_results", 3)

    if is_binary(query) do
      case Ollama.web_search(client, query: query, max_results: max_results) do
        {:ok, results} -> {:ok, wrap_json(results)}
        {:error, error} -> {:error, Exception.message(error)}
      end
    else
      {:error, "web_search requires a query string"}
    end
  end

  defp call_tool(%{"name" => "web_fetch", "arguments" => args}, client) do
    url = Map.get(args, "url")

    if is_binary(url) do
      case Ollama.web_fetch(client, url: url) do
        {:ok, result} -> {:ok, wrap_json(result)}
        {:error, error} -> {:error, Exception.message(error)}
      end
    else
      {:error, "web_fetch requires a url string"}
    end
  end

  defp call_tool(%{"name" => name}, _client), do: {:error, "Unknown tool: #{name}"}
  defp call_tool(_, _client), do: {:error, "Invalid tool call payload"}

  defp respond(id, result) do
    payload = %{"jsonrpc" => "2.0", "id" => id, "result" => result}
    IO.puts(Jason.encode!(payload))
  end

  defp respond_error(id, message) do
    payload = %{
      "jsonrpc" => "2.0",
      "id" => id,
      "error" => %{"code" => -32_000, "message" => message}
    }

    IO.puts(Jason.encode!(payload))
  end

  defp wrap_json(result) do
    %{"content" => [%{"type" => "json", "json" => result}]}
  end

  defp tools do
    [
      %{
        "name" => "web_search",
        "description" => "Search the web using Ollama's hosted API.",
        "inputSchema" => %{
          "type" => "object",
          "properties" => %{
            "query" => %{"type" => "string", "description" => "Search query"},
            "max_results" => %{
              "type" => "integer",
              "description" => "Max results",
              "default" => 3
            }
          },
          "required" => ["query"]
        }
      },
      %{
        "name" => "web_fetch",
        "description" => "Fetch and summarize a web page.",
        "inputSchema" => %{
          "type" => "object",
          "properties" => %{
            "url" => %{"type" => "string", "description" => "URL to fetch"}
          },
          "required" => ["url"]
        }
      }
    ]
  end
end

OllamaMCP.Server.start(client)
