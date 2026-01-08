liveview_source = ~S"""
defmodule MyAppWeb.ChatLive do
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    {:ok, assign(socket, messages: [], response: "", streaming: false)}
  end

  def handle_event("submit", %{"prompt" => prompt}, socket) do
    client = Ollama.init()

    messages = socket.assigns.messages ++ [%{role: "user", content: prompt}]

    {:ok, task} =
      Ollama.chat(client,
        model: "llama3.2",
        messages: messages,
        stream: self()
      )

    {:noreply,
     assign(socket,
       messages: messages,
       response: "",
       streaming: true,
       task: task
     )}
  end

  def handle_info({_pid, {:data, %{"done" => false} = chunk}}, socket) do
    content = get_in(chunk, ["message", "content"]) || ""
    {:noreply, update(socket, :response, &(&1 <> content))}
  end

  def handle_info({_pid, {:data, %{"done" => true}}}, socket) do
    messages =
      socket.assigns.messages ++
        [
          %{role: "assistant", content: socket.assigns.response}
        ]

    {:noreply, assign(socket, messages: messages, response: "", streaming: false)}
  end

  def handle_info({ref, {:ok, _response}}, socket) do
    Process.demonitor(ref, [:flush])
    {:noreply, socket}
  end
end
"""

if Code.ensure_loaded?(Phoenix.LiveView) do
  Code.eval_string(liveview_source)
else
  IO.puts(
    "Phoenix LiveView not available. Add phoenix_live_view and ollama to your app and paste:"
  )

  IO.puts(liveview_source)
end
