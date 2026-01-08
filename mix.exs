defmodule Ollama.MixProject do
  use Mix.Project

  def project do
    [
      app: :ollama,
      name: "Ollama",
      description: "A nifty little library for working with Ollama in Elixir.",
      source_url: "https://github.com/lebrunel/ollama-ex",
      version: "0.10.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: [
        name: "ollama",
        files: ~w(lib media .formatter.exs mix.exs README.md LICENSE),
        licenses: ["Apache-2.0"],
        links: %{
          "GitHub" => "https://github.com/lebrunel/ollama-ex"
        }
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bandit, "~> 1.10", only: :test},
      {:ex_doc, "~> 0.39", only: :dev, runtime: false},
      {:jason, "~> 1.4"},
      {:nimble_options, "~> 1.1"},
      {:plug, "~> 1.19"},
      {:req, "~> 0.5"},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:supertester, "~> 0.5.0", only: :test}
    ]
  end

  defp docs do
    [
      main: "overview",
      assets: %{"media" => "media"},
      extras: [
        {"README.md", title: "Overview", filename: "overview"},
        {"guides/getting-started.md", title: "Getting Started"},
        {"guides/ollama-setup.md", title: "Ollama Server Setup"},
        {"guides/streaming.md", title: "Streaming"},
        {"guides/tools.md", title: "Tools"},
        {"guides/structured-outputs.md", title: "Structured Outputs"},
        {"guides/thinking.md", title: "Thinking Mode"},
        {"guides/embeddings.md", title: "Embeddings"},
        {"guides/multimodal.md", title: "Multimodal"},
        {"guides/cloud-api.md", title: "Cloud API"},
        {"guides/cheatsheet.md", title: "Cheatsheet"},
        {"examples/README.md", title: "Examples", filename: "examples"},
        {"LICENSE", title: "License"}
      ],
      groups_for_extras: [
        Overview: ["overview"],
        Guides: ~r/guides\/.*/,
        Examples: ["examples"],
        Project: ["LICENSE"]
      ],
      groups_for_modules: [
        Client: [Ollama],
        Errors: [Ollama.RequestError, Ollama.ResponseError, Ollama.Errors, Ollama.Retry],
        Helpers: [Ollama.Image, Ollama.Tool, Ollama.Options, Ollama.Options.Presets],
        Web: [
          Ollama.Web,
          Ollama.Web.SearchResponse,
          Ollama.Web.SearchResult,
          Ollama.Web.FetchResponse,
          Ollama.Web.Tools
        ],
        Types: [
          Ollama.Types,
          Ollama.Types.Base,
          Ollama.Types.Logprob,
          Ollama.Types.ToolCall,
          Ollama.Types.Message,
          Ollama.Types.GenerateResponse,
          Ollama.Types.ChatResponse,
          Ollama.Types.EmbedResponse,
          Ollama.Types.EmbeddingsResponse,
          Ollama.Types.ModelDetails,
          Ollama.Types.ModelInfo,
          Ollama.Types.ListResponse,
          Ollama.Types.ShowResponse,
          Ollama.Types.ProcessResponse,
          Ollama.Types.ProgressResponse,
          Ollama.Types.StatusResponse
        ],
        Internals: [Ollama.Blob, Ollama.Schemas, Ollama.HTTPError]
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test"]
  defp elixirc_paths(_), do: ["lib"]
end
