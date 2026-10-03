# shellcheck shell=bash disable=SC2034
# Shared settings for setup.sh and verify.sh.
# Override any of these per run, e.g.:  MODEL=qwen3.5:4b ./setup.sh

# The model used in the video. gemma4:e2b is the model Ollama's own quickstart uses.
MODEL="${MODEL:-gemma4:e2b}"

# Smaller fallback for 8 GB Macs (4-bit QAT build, ~4.3 GB download).
SMALL_MODEL="${SMALL_MODEL:-gemma4:e2b-it-qat}"

# The Ollama version this folder was tested with (see TESTED.md).
# setup.sh warns, but does not stop, if yours is different.
TESTED_OLLAMA_VERSION="${TESTED_OLLAMA_VERSION:-0.35.1}"

# Where the local Ollama server listens. This is Ollama's default.
OLLAMA_URL="${OLLAMA_URL:-http://127.0.0.1:11434}"

# Lowest macOS major version Ollama supports (macOS 14 Sonoma).
MIN_MACOS_MAJOR=14
