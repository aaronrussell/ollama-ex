# Ollama Server Setup

This guide covers installing Ollama, running the local server, pulling models,
and connecting to local or cloud endpoints from the Elixir client.

## Install Ollama

### macOS and Windows

Download the installer for your platform:

- https://ollama.com/download

### Linux (quick install)

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

### Linux (manual install)

If you are upgrading from an older version, remove the old libraries first:

```bash
sudo rm -rf /usr/lib/ollama
```

Download and extract the package:

```bash
curl -fsSL https://ollama.com/download/ollama-linux-amd64.tgz \
  | sudo tar zx -C /usr
```

Start the server:

```bash
ollama serve
```

Verify:

```bash
ollama -v
```

#### AMD GPU (ROCm)

```bash
curl -fsSL https://ollama.com/download/ollama-linux-amd64-rocm.tgz \
  | sudo tar zx -C /usr
```

#### ARM64

```bash
curl -fsSL https://ollama.com/download/ollama-linux-arm64.tgz \
  | sudo tar zx -C /usr
```

## Run as a systemd service (recommended)

Create a dedicated user and group:

```bash
sudo useradd -r -s /bin/false -U -m -d /usr/share/ollama ollama
sudo usermod -a -G ollama $(whoami)
```

Create `/etc/systemd/system/ollama.service`:

```ini
[Unit]
Description=Ollama Service
After=network-online.target

[Service]
ExecStart=/usr/bin/ollama serve
User=ollama
Group=ollama
Restart=always
RestartSec=3
Environment="PATH=$PATH"

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable ollama
sudo systemctl start ollama
```

Check status:

```bash
systemctl status ollama
```

## GPU Drivers (Optional)

### NVIDIA CUDA

Install CUDA drivers from:

- https://developer.nvidia.com/cuda-downloads

Verify:

```bash
nvidia-smi
```

### AMD ROCm

Install ROCm from:

- https://rocm.docs.amd.com/projects/install-on-linux/en/latest/tutorial/quick-start.html

For newer GPU support, consider the latest AMD drivers:

- https://www.amd.com/en/support/linux-drivers

## Customization

Edit the systemd service or add overrides:

```bash
sudo systemctl edit ollama
```

Example override (`/etc/systemd/system/ollama.service.d/override.conf`):

```ini
[Service]
Environment="OLLAMA_DEBUG=1"
```

## Updating

Re-run the install script:

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

Or re-download the package:

```bash
curl -fsSL https://ollama.com/download/ollama-linux-amd64.tgz \
  | sudo tar zx -C /usr
```

### Installing a specific version

```bash
curl -fsSL https://ollama.com/install.sh | OLLAMA_VERSION=0.5.7 sh
```

## Uninstall

Stop and remove the service:

```bash
sudo systemctl stop ollama
sudo systemctl disable ollama
sudo rm /etc/systemd/system/ollama.service
```

Remove libraries and binaries:

```bash
sudo rm -r $(which ollama | tr 'bin' 'lib')
sudo rm $(which ollama)
```

Remove models and service user:

```bash
sudo userdel ollama
sudo groupdel ollama
sudo rm -r /usr/share/ollama
```

## Start the Server

If you are not using systemd, start manually:

```bash
ollama serve
```

The default base URL is `http://localhost:11434`.

## Pull a Model

```bash
ollama pull llama3.2
```

For examples, also pull:

```bash
ollama pull nomic-embed-text
ollama pull llava
ollama pull deepseek-r1:1.5b
```

Thinking examples use `deepseek-r1:1.5b`, which supports `think`.

Browse models:

- https://ollama.com/search

List local models:

```bash
ollama list
```

## Connect from Elixir

By default, the client targets `http://localhost:11434`:

```elixir
client = Ollama.init()
```

Override the host with `OLLAMA_HOST`:

```bash
export OLLAMA_HOST="http://ollama.internal:11434"
```

Or pass the URL directly:

```elixir
client = Ollama.init("http://ollama.internal:11434")
```

## Cloud Models (via Local Ollama)

Cloud models let you run larger models while keeping the same local workflow.
See https://ollama.com/search?c=cloud for the latest list.

1) Sign in (one time):

```bash
ollama signin
```

2) Pull a cloud model:

```bash
ollama pull gpt-oss:120b-cloud
```

3) Use it like any other model:

```elixir
{:ok, stream} = Ollama.chat(client,
  model: "gpt-oss:120b-cloud",
  messages: [%{role: "user", content: "Why is the sky blue?"}],
  stream: true
)

stream
|> Stream.each(fn chunk ->
  IO.write(get_in(chunk, ["message", "content"]) || "")
end)
|> Stream.run()
```

## Cloud API (ollama.com)

1) Create an API key: https://ollama.com/settings/keys

2) Export the key:

```bash
export OLLAMA_API_KEY="your_api_key_here"
```

3) (Optional) List models:

```bash
curl https://ollama.com/api/tags
```

4) Point the client at the hosted API:

```elixir
client = Ollama.init("https://ollama.com")

{:ok, response} = Ollama.chat(client,
  model: "gpt-oss:120b",
  messages: [%{role: "user", content: "Why is the sky blue?"}]
)
```

### Web search/fetch (requires API key)

`web_search/2` and `web_fetch/2` always call the hosted API and require
`OLLAMA_API_KEY`. If the key is missing, these examples will skip; if the key
is invalid, the API will return 401/403.

You can validate the key with:

```bash
curl -H "Authorization: Bearer $OLLAMA_API_KEY" https://ollama.com/api/tags
```

### Cloud test runs (optional)

Cloud tests are tagged and excluded by default. After setting
`OLLAMA_API_KEY`, you can run:

```bash
mix test --include cloud_api
```

## Troubleshooting

- `connection refused`: ensure `ollama serve` is running and reachable.
- Wrong host/port: set `OLLAMA_HOST` or pass a URL to `Ollama.init/1`.
- Auth errors: confirm your API key and target host.

## Next Steps

- [Getting Started](getting-started.md)
- [Streaming](streaming.md)
- [Tools](tools.md)
- [Structured Outputs](structured-outputs.md)
- [Examples](../examples/README.md)
