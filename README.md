# Run a Local LLM on Your Mac with Ollama (2026 Setup)

Companion code for the Ring Zero video **[How to Run a Local LLM on Your Mac with Ollama (2026 Setup)](https://www.youtube.com/@RingZero-l5v)** <!-- TODO: replace with the video URL -->

Your own AI, running on your Mac, even with the Wi-Fi off. Free, no account, about four commands.

Tested setup: see [TESTED.md](TESTED.md).

## What you need

- macOS 14 Sonoma or newer
- An Apple Silicon Mac (M1 or later) is best. Intel Macs work, but Ollama runs them on the CPU only, so answers are slower.
- About 8 GB of free disk space for the model

## Quick start

```bash
git clone https://github.com/sreejithsr441/Ollama-mac-setup.git
cd ring-zero-examples/ollama-mac-setup
./setup.sh      # checks your Mac, installs/starts Ollama, downloads the model
./verify.sh     # runs a test prompt and measures speed
```

`setup.sh` asks before installing anything. On a Mac with 8 GB of memory or less, it picks the smaller `gemma4:e2b-it-qat` model.

Use a different model with `MODEL=`, for example `MODEL=qwen3.5:4b ./setup.sh`.

## The steps from the video

Each step below matches a chapter in the video.

### 1. Install Ollama on Mac

Download the app from [ollama.com/download/mac](https://ollama.com/download/mac), drag it to Applications and open it. Or use Homebrew:

```bash
brew install --cask ollama-app
```

Check it worked:

```bash
ollama --version
```

### 2. First run

```bash
ollama
```

The first time, Ollama walks you through a short setup. Signing in is only for Ollama's cloud models. To keep everything on your Mac, choose a local model.

### 3. Download your first AI model

```bash
ollama pull gemma4:e2b
ollama ls
```

### 4. Chat with it in Terminal

```bash
ollama run gemma4:e2b --verbose
```

Ask anything. `--verbose` prints the speed (eval rate, in tokens per second) after each answer. Type `/bye` to leave.

### 5. Turn off Wi-Fi: prove it's local

Turn off Wi-Fi, then:

```bash
./verify.sh --offline
```

It refuses to run if your Mac can still reach the internet, so the result really is offline. In another Terminal window, check where the model is running:

```bash
ollama ps
```

On Apple Silicon, the `PROCESSOR` column should say `100% GPU`.

### 6. Use your local AI from code

While Ollama is open, it runs a server on your Mac at `http://localhost:11434`. Only your Mac can reach it by default.

```bash
./examples/chat.sh "Why is the sky blue?"        # curl, the call from the video
python3 examples/chat.py "Why is the sky blue?"  # Python, standard library only, streams the answer
```

The raw call:

```bash
curl -s http://localhost:11434/api/chat -d '{
  "model": "gemma4:e2b",
  "messages": [{ "role": "user", "content": "Why is the sky blue?" }],
  "stream": false
}'
```

### 7. Faster on bigger Macs: MLX models

In 2026 Ollama added Apple's MLX engine. Today you opt in by choosing a model whose tag ends in `-mlx`:

```bash
ollama pull gemma4:12b-mlx
MODEL=gemma4:12b ./verify.sh       # normal engine (pull gemma4:12b first)
MODEL=gemma4:12b-mlx ./verify.sh   # MLX engine
```

Ollama's v0.40 release (a pre-release on Sep 25, 2026) runs supported models on MLX automatically on Apple Silicon. Bigger models need more memory: `gemma4:12b-mlx` is a 7.7 GB download.

## Troubleshooting

| You see | What it means | Fix |
| --- | --- | --- |
| `model requires more system memory` | The model doesn't fit in your free memory | Close heavy apps, or use a smaller model: `ollama run gemma4:e2b-it-qat` |
| `could not connect` / `connection refused` | The Ollama server isn't running | Open the Ollama app, or run `ollama serve` |
| `address already in use` | Something else is using port 11434, often a second copy of Ollama | `lsof -i :11434` to find it, quit it, then open Ollama again |
| `model not found` | Not downloaded yet, or a typo in the name | `ollama ls`, then `ollama pull <exact name>` |
| Very slow answers | The model is partly on the CPU | `ollama ps`: if it doesn't say `100% GPU`, use a smaller model |
| Download stuck or `digest mismatch` | An interrupted download | Update Ollama, then `ollama rm <model>` and pull again |

Logs: `cat ~/.ollama/logs/server.log`

## Useful extras

```bash
ollama stop gemma4:e2b    # unload it from memory now (otherwise it unloads after 5 idle minutes)
ollama rm gemma4:e2b      # delete the model from disk
ollama show gemma4:e2b    # details: size, context length, capabilities
```

- Models are stored in `~/.ollama/models`.
- Ollama's docs say the default context window depends on memory: under 24 GB → 4k tokens, 24–48 GB → 32k, 48 GB+ → 256k. Check yours in the `CONTEXT` column of `ollama ps`, and change it with the slider in Ollama's Settings.

## Files

| File | What it does |
| --- | --- |
| `setup.sh` | Checks macOS version, chip and memory; installs Ollama with Homebrew if you say yes; starts it; downloads the model |
| `verify.sh` | Warm-up run, then timed runs through the local API; prints median tokens/s, `ollama ps`, and a line for TESTED.md. `--runs N`, `--offline` |
| `config.sh` | Model names, tested Ollama version, server URL |
| `lib.sh` | Shared helpers (no extra installs needed; uses `jq` if you have it, otherwise macOS's built-in JavaScript) |
| `examples/chat.sh`, `examples/chat.py` | One chat request from Terminal and from Python |
| `TESTED.md` | Machines, versions and speeds this was tested with |

## Sources

- [Ollama for macOS](https://ollama.com/download/mac) · [macOS docs](https://docs.ollama.com/macos) · [CLI reference](https://docs.ollama.com/cli) · [FAQ](https://docs.ollama.com/faq) · [Context length](https://docs.ollama.com/context-length)
- [Gemma 4 models](https://ollama.com/library/gemma4/tags) · [Ollama releases](https://github.com/ollama/ollama/releases)
