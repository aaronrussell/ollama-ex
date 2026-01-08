ExUnit.start(exclude: [:cloud_api])

# Load test support modules
for {module, file} <- [
      {Ollama.MockServer, "support/mock_server.ex"},
      {Ollama.StreamCatcher, "support/stream_catcher.ex"},
      {Ollama.TestHelpers, "support/test_helpers.ex"}
    ] do
  unless Code.ensure_loaded?(module) do
    Code.require_file(file, __DIR__)
  end
end

# Start the mock server
{:ok, _pid} = Bandit.start_link(plug: Ollama.MockServer, port: 4000)
