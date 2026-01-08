# Streaming Responses

Ollama supports streaming for real-time response delivery. The Elixir client
provides two streaming modes to fit different use cases.

## Overview

| Mode | Option | Returns | Best For |
|------|--------|---------|----------|
| Enumerable | `stream: true` | `Stream.t()` | Scripts, one-off processing |
| Process | `stream: pid` | `Task.t()` | GenServers, LiveView |

## Enumerable Mode

When `stream: true`, you receive a lazy `Stream` that yields response chunks.

```elixir
{:ok, stream} = Ollama.chat(client,
  model: "llama3.2",
  messages: messages,
  stream: true
)

# Process each chunk as it arrives
stream
|> Stream.each(fn chunk ->
  IO.write(chunk["message"]["content"] || "")
end)
|> Stream.run()
```

### Pros
- Simple enumeration with `Enum` or `Stream`
- Easy to compose with other Stream operations
- Works well in scripts and one-off tasks

### Cons
- Uses `receive/0` internally
- **Not safe in GenServer callbacks** (blocks the process)

### Collecting Results

```elixir
chunks = Enum.to_list(stream)
full_response = chunks
  |> Enum.map(& &1["message"]["content"])
  |> Enum.join("")
```

## Process Mode

When `stream: pid`, messages are sent to the specified process.

```elixir
{:ok, task} = Ollama.chat(client,
  model: "llama3.2",
  messages: messages,
  stream: self()
)

# Messages arrive as:
# {task_pid, {:data, %{"message" => ..., "done" => false}}}
# {task_pid, {:data, %{"message" => ..., "done" => true}}}
# {task_ref, {:ok, %Req.Response{status: 200}}}
```

### Pros
- Non-blocking for the caller
- Safe in GenServer/LiveView callbacks
- Proper OTP supervision

### Cons
- More setup required
- Must handle messages explicitly

## Phoenix LiveView Integration

Process mode is ideal for LiveView:

```elixir
defmodule MyAppWeb.ChatLive do
  use Phoenix.LiveView

  def handle_event("send", %{"message" => msg}, socket) do
    messages = socket.assigns.messages ++ [%{role: "user", content: msg}]

    {:ok, task} = Ollama.chat(socket.assigns.client,
      model: "llama3.2",
      messages: messages,
      stream: self()
    )

    {:noreply, assign(socket,
      messages: messages,
      streaming: true,
      current_response: "",
      task: task
    )}
  end

  # Handle streaming chunks
  def handle_info({pid, {:data, %{"done" => false} = chunk}}, socket)
      when pid == socket.assigns.task.pid do
    content = get_in(chunk, ["message", "content"]) || ""
    {:noreply, update(socket, :current_response, &(&1 <> content))}
  end

  # Handle stream completion
  def handle_info({pid, {:data, %{"done" => true}}}, socket)
      when pid == socket.assigns.task.pid do
    messages = socket.assigns.messages ++ [
      %{role: "assistant", content: socket.assigns.current_response}
    ]
    {:noreply, assign(socket,
      messages: messages,
      streaming: false,
      current_response: ""
    )}
  end

  # Handle task completion
  def handle_info({ref, {:ok, _response}}, socket) do
    Process.demonitor(ref, [:flush])
    {:noreply, socket}
  end
end
```

## Error Handling

### Enumerable Mode

```elixir
try do
  stream |> Stream.each(&process/1) |> Stream.run()
rescue
  e in Ollama.HTTPError ->
    Logger.error("Stream error: #{e.message}")
end
```

### Process Mode

```elixir
def handle_info({ref, {:error, reason}}, socket) do
  Process.demonitor(ref, [:flush])
  {:noreply, assign(socket, error: reason, streaming: false)}
end
```

## Choosing a Mode

```
┌─────────────────────────────────────────┐
│ Are you in a GenServer/LiveView?        │
└────────────────┬────────────────────────┘
                 │
         ┌───────┴───────┐
         │ Yes           │ No
         ▼               ▼
    ┌────────────┐  ┌────────────┐
    │ Use        │  │ Use        │
    │ stream:    │  │ stream:    │
    │ self()     │  │ true       │
    └────────────┘  └────────────┘
```
