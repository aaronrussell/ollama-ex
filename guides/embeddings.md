# Embeddings

Embeddings convert text into numerical vectors that capture semantic meaning.
These vectors enable similarity search, clustering, and retrieval-augmented
generation (RAG).

## Overview

```elixir
{:ok, response} = Ollama.embed(client,
  model: "nomic-embed-text",
  input: "The quick brown fox"
)

embedding = hd(response["embeddings"])
# => [0.123, -0.456, 0.789, ...]
```

## Single vs Batch Embeddings

### Single Text

```elixir
{:ok, response} = Ollama.embed(client,
  model: "nomic-embed-text",
  input: "Hello world"
)

[embedding] = response["embeddings"]
```

### Batch Processing

Process multiple texts efficiently in one request:

```elixir
texts = [
  "The sky is blue",
  "The grass is green",
  "The sun is yellow"
]

{:ok, response} = Ollama.embed(client,
  model: "nomic-embed-text",
  input: texts
)

embeddings = response["embeddings"]
# => [[...], [...], [...]]
```

## Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `model` | string | Embedding model name (required) |
| `input` | string or list | Text(s) to embed (required) |
| `truncate` | boolean | Truncate input to max token length |
| `dimensions` | integer | Reduce embedding dimensions |
| `keep_alive` | string | How long to keep model loaded |

### Dimension Reduction

Reduce embedding size for storage efficiency:

```elixir
{:ok, response} = Ollama.embed(client,
  model: "nomic-embed-text",
  input: "Hello world",
  dimensions: 256  # Reduce from default (e.g., 768)
)
```

### Truncation

Handle long texts that exceed model limits:

```elixir
{:ok, response} = Ollama.embed(client,
  model: "nomic-embed-text",
  input: very_long_text,
  truncate: true
)
```

## Embedding Models

| Model | Dimensions | Use Case |
|-------|------------|----------|
| `nomic-embed-text` | 768 | General purpose |
| `mxbai-embed-large` | 1024 | Higher quality |
| `all-minilm` | 384 | Faster, smaller |

Install a model:

```bash
ollama pull nomic-embed-text
```

## Similarity Search

Calculate cosine similarity between embeddings:

```elixir
defmodule Similarity do
  def cosine(a, b) do
    dot = Enum.zip(a, b) |> Enum.map(fn {x, y} -> x * y end) |> Enum.sum()
    mag_a = :math.sqrt(Enum.map(a, &(&1 * &1)) |> Enum.sum())
    mag_b = :math.sqrt(Enum.map(b, &(&1 * &1)) |> Enum.sum())
    dot / (mag_a * mag_b)
  end
end

# Embed query and documents
{:ok, query_resp} = Ollama.embed(client,
  model: "nomic-embed-text",
  input: "What is machine learning?"
)

{:ok, docs_resp} = Ollama.embed(client,
  model: "nomic-embed-text",
  input: [
    "Machine learning is a subset of AI",
    "The weather is nice today",
    "Neural networks learn from data"
  ]
)

[query_emb] = query_resp["embeddings"]
doc_embs = docs_resp["embeddings"]

# Find most similar document
similarities = Enum.map(doc_embs, &Similarity.cosine(query_emb, &1))
# => [0.89, 0.12, 0.85]
```

## RAG Pattern

Use embeddings for retrieval-augmented generation:

```elixir
defmodule RAG do
  def answer(client, question, documents) do
    # 1. Embed the question
    {:ok, q_resp} = Ollama.embed(client,
      model: "nomic-embed-text",
      input: question
    )
    [query_emb] = q_resp["embeddings"]

    # 2. Embed documents
    {:ok, d_resp} = Ollama.embed(client,
      model: "nomic-embed-text",
      input: documents
    )

    # 3. Find top-k similar documents
    similarities =
      d_resp["embeddings"]
      |> Enum.with_index()
      |> Enum.map(fn {emb, idx} ->
        {Similarity.cosine(query_emb, emb), Enum.at(documents, idx)}
      end)
      |> Enum.sort_by(&elem(&1, 0), :desc)
      |> Enum.take(3)

    context = Enum.map_join(similarities, "\n", &elem(&1, 1))

    # 4. Generate answer with context
    {:ok, response} = Ollama.chat(client,
      model: "llama3.2",
      messages: [
        %{role: "system", content: "Answer based on the context provided."},
        %{role: "user", content: "Context:\n#{context}\n\nQuestion: #{question}"}
      ]
    )

    response["message"]["content"]
  end
end
```

## Database Integration

### PostgreSQL with pgvector

```elixir
# Store embeddings
{:ok, response} = Ollama.embed(client,
  model: "nomic-embed-text",
  input: document_text
)
[embedding] = response["embeddings"]

Repo.insert!(%Document{
  content: document_text,
  embedding: Pgvector.new(embedding)
})

# Query similar documents
query_embedding = get_query_embedding(client, query)
Repo.all(
  from d in Document,
  order_by: fragment("embedding <-> ?", ^Pgvector.new(query_embedding)),
  limit: 5
)
```

## Typed Responses

```elixir
{:ok, response} = Ollama.embed(client,
  model: "nomic-embed-text",
  input: ["text1", "text2"],
  response_format: :struct
)

response.embeddings  # List of embedding vectors
response.model       # Model used
```

## Performance Tips

1. **Batch requests** - Embed multiple texts in one call
2. **Reduce dimensions** - Use `dimensions` for storage savings
3. **Cache embeddings** - Store computed embeddings
4. **Choose appropriate model** - Smaller models for speed

## Legacy Embeddings API

The older `embeddings/2` function is still available but deprecated:

```elixir
# Legacy (single prompt only)
{:ok, response} = Ollama.embeddings(client,
  model: "llama3.2",
  prompt: "Hello world"
)
embedding = response["embedding"]

# Preferred (supports batch)
{:ok, response} = Ollama.embed(client,
  model: "nomic-embed-text",
  input: "Hello world"
)
```

## See Also

- [Examples](../examples/README.md) - Working embedding examples
- [Cheatsheet](cheatsheet.md) - Quick reference
