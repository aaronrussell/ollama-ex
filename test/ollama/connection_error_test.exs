defmodule Ollama.ConnectionErrorTest do
  use Supertester.ExUnitFoundation, isolation: :basic

  alias Ollama.ConnectionError

  test "wraps transport errors with a helpful message" do
    stub = __MODULE__

    Req.Test.stub(stub, fn conn ->
      Req.Test.transport_error(conn, :econnrefused)
    end)

    req = Req.new(base_url: "http://ollama.test", plug: {Req.Test, stub})
    client = Ollama.init(req)

    assert {:error, %ConnectionError{} = error} = Ollama.list_models(client)
    message = Exception.message(error)

    assert String.contains?(message, "Could not connect to Ollama")
    assert String.contains?(message, "https://ollama.com/download")
  end
end
