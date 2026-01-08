defmodule Ollama.AliasesTest do
  use Supertester.ExUnitFoundation, isolation: :full_isolation, async: false

  setup_all do
    {:ok, client: Ollama.init("http://localhost:4000")}
  end

  test "generate/2 delegates to completion/2", %{client: client} do
    assert {:ok, res} = Ollama.generate(client, model: "llama2", prompt: "Hello")
    assert res["model"] == "llama2"
  end

  test "list/1 delegates to list_models/1", %{client: client} do
    assert {:ok, res} = Ollama.list(client)
    assert is_list(res["models"])
  end

  test "show/2 delegates to show_model/2", %{client: client} do
    assert {:ok, res} = Ollama.show(client, name: "llama2")
    assert is_map(res)
  end

  test "ps/1 delegates to list_running/1", %{client: client} do
    assert {:ok, res} = Ollama.ps(client)
    assert is_list(res["models"])
  end

  test "pull/2 delegates to pull_model/2", %{client: client} do
    assert {:ok, res} = Ollama.pull(client, name: "llama2")
    assert res["status"] == "success"
  end

  test "push/2 delegates to push_model/2", %{client: client} do
    assert {:ok, res} = Ollama.push(client, name: "llama2")
    assert res["status"] == "success"
  end

  test "create/2 delegates to create_model/2", %{client: client} do
    assert {:ok, res} = Ollama.create(client, name: "llama2")
    assert res["status"] == "success"
  end

  test "copy/2 delegates to copy_model/2", %{client: client} do
    assert {:ok, true} = Ollama.copy(client, source: "llama2", destination: "llama2-copy")
  end

  test "delete/2 delegates to delete_model/2", %{client: client} do
    assert {:ok, true} = Ollama.delete(client, name: "llama2")
  end
end
