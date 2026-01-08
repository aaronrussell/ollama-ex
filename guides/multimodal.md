# Multimodal (Vision)

Multimodal models can process both text and images, enabling image analysis,
OCR, chart interpretation, and visual question answering.

## Overview

```elixir
{:ok, response} = Ollama.chat(client,
  model: "llava",
  messages: [
    %{role: "user", content: "Describe this image.", images: ["/path/to/photo.jpg"]}
  ]
)

IO.puts(response["message"]["content"])
```

## Image Input Methods

### File Path (Recommended)

The client automatically encodes images from file paths:

```elixir
{:ok, response} = Ollama.chat(client,
  model: "llava",
  messages: [
    %{role: "user", content: "What's in this image?", images: ["./photo.jpg"]}
  ]
)
```

### Pre-encoded Base64

Encode images manually if needed:

```elixir
base64_image = Ollama.Image.encode("/path/to/image.png")

{:ok, response} = Ollama.chat(client,
  model: "llava",
  messages: [
    %{role: "user", content: "Describe this.", images: [base64_image]}
  ]
)
```

### Binary Data

Pass raw binary image data:

```elixir
image_binary = File.read!("/path/to/image.jpg")

{:ok, response} = Ollama.chat(client,
  model: "llava",
  messages: [
    %{role: "user", content: "What do you see?", images: [image_binary]}
  ]
)
```

## Supported Image Formats

| Format | Extension | Notes |
|--------|-----------|-------|
| PNG | `.png` | Best compatibility |
| JPEG | `.jpg`, `.jpeg` | Widely supported |
| WebP | `.webp` | Some models only |

PNG and JPEG are recommended for maximum model compatibility.

## Vision Models

| Model | Size | Capabilities |
|-------|------|--------------|
| `llava` | 7B | General vision |
| `llava:13b` | 13B | Higher quality |
| `llama3.2-vision` | 11B | Latest Llama vision |
| `gemma3` | Various | Multimodal support |
| `qwen2-vl` | Various | Vision-language |

Install a vision model:

```bash
ollama pull llava
```

## Multiple Images

Analyze multiple images in one request:

```elixir
{:ok, response} = Ollama.chat(client,
  model: "llava",
  messages: [
    %{
      role: "user",
      content: "Compare these two images.",
      images: ["./image1.jpg", "./image2.jpg"]
    }
  ]
)
```

## With Completion Endpoint

Use images with the generate/completion API:

```elixir
{:ok, response} = Ollama.completion(client,
  model: "llava",
  prompt: "Describe what you see:",
  images: ["/path/to/image.jpg"]
)

IO.puts(response["response"])
```

## Structured Image Analysis

Combine vision with JSON schema for structured output:

```elixir
schema = %{
  type: "object",
  properties: %{
    objects: %{type: "array", items: %{type: "string"}},
    scene: %{type: "string"},
    colors: %{type: "array", items: %{type: "string"}}
  },
  required: ["objects", "scene"]
}

{:ok, response} = Ollama.chat(client,
  model: "llava",
  messages: [
    %{
      role: "user",
      content: "Analyze this image and identify objects, scene type, and colors.",
      images: ["./photo.jpg"]
    }
  ],
  format: schema
)

{:ok, analysis} = Jason.decode(response["message"]["content"])
# => %{"objects" => ["tree", "car"], "scene" => "street", "colors" => ["green", "blue"]}
```

## Streaming Image Responses

Stream responses for long image descriptions:

```elixir
{:ok, stream} = Ollama.chat(client,
  model: "llava",
  messages: [
    %{role: "user", content: "Describe this image in detail.", images: ["./photo.jpg"]}
  ],
  stream: true
)

stream
|> Stream.each(fn chunk ->
  if content = get_in(chunk, ["message", "content"]) do
    IO.write(content)
  end
end)
|> Stream.run()
```

## Multi-turn Visual Conversations

Continue conversations about images:

```elixir
messages = [
  %{role: "user", content: "What's in this image?", images: ["./chart.png"]},
  # After first response, continue without re-sending image
  %{role: "assistant", content: "This is a bar chart showing sales data..."},
  %{role: "user", content: "What's the highest value shown?"}
]

{:ok, response} = Ollama.chat(client,
  model: "llava",
  messages: messages
)
```

## Use Cases

### OCR (Text Extraction)

```elixir
{:ok, response} = Ollama.chat(client,
  model: "llava",
  messages: [
    %{role: "user", content: "Extract all text from this image.", images: ["./document.png"]}
  ]
)
```

### Chart Analysis

```elixir
{:ok, response} = Ollama.chat(client,
  model: "llava",
  messages: [
    %{
      role: "user",
      content: "Analyze this chart and summarize the key trends.",
      images: ["./chart.png"]
    }
  ]
)
```

### Image Classification

```elixir
schema = %{
  type: "object",
  properties: %{
    category: %{type: "string", enum: ["animal", "vehicle", "building", "nature", "other"]},
    confidence: %{type: "string", enum: ["high", "medium", "low"]}
  },
  required: ["category", "confidence"]
}

{:ok, response} = Ollama.chat(client,
  model: "llava",
  messages: [
    %{role: "user", content: "Classify this image.", images: ["./photo.jpg"]}
  ],
  format: schema
)
```

## Error Handling

Handle resource-intensive vision models:

```elixir
case Ollama.chat(client, model: "llava", messages: messages) do
  {:ok, response} ->
    response

  {:error, %Ollama.ResponseError{status: 500}} ->
    # Model runner crashed, try CPU fallback
    {:ok, response} = Ollama.chat(client,
      model: "llava",
      messages: messages,
      options: [num_gpu: 0, num_ctx: 1024]
    )
    response

  {:error, error} ->
    raise "Vision request failed: #{inspect(error)}"
end
```

## Performance Tips

1. **Resize large images** - Smaller images process faster
2. **Use appropriate models** - Smaller models for simple tasks
3. **Limit context** - Use `num_ctx` option for memory constraints
4. **CPU fallback** - Use `num_gpu: 0` if GPU runs out of memory

## Image Encoding Helper

```elixir
# Encode a file
base64 = Ollama.Image.encode("/path/to/image.jpg")

# Check if already encoded
Ollama.Image.base64?("iVBORw0KGgo...")  # => true
Ollama.Image.base64?("/path/to/file")    # => false
```

## See Also

- [Examples](../examples/README.md) - Working multimodal examples
- [Streaming Guide](streaming.md) - Stream image responses
- [Structured Outputs](structured-outputs.md) - Schema with images
