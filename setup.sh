#!/usr/bin/env bash
# Ring Zero — How to Run a Local LLM on Your Mac with Ollama (2026 Setup)
#
# Checks your Mac, installs Ollama if needed (with your OK), starts it,
# and downloads the model from the video.
#
# Usage:
#   ./setup.sh            # interactive
#   ./setup.sh --yes      # don't ask before installing with Homebrew
#   MODEL=qwen3.5:4b ./setup.sh   # use a different model
set -euo pipefail

cd "$(dirname "$0")"
MODEL_FROM_USER="${MODEL:-}"
# shellcheck source=config.sh
source ./config.sh
# shellcheck source=lib.sh
source ./lib.sh

ASSUME_YES=0
for arg in "$@"; do
  case "$arg" in
    -y|--yes) ASSUME_YES=1 ;;
    -h|--help) sed -n '2,11p' "$0"; exit 0 ;;
    *) fail "Unknown option: $arg (try --help)" ;;
  esac
done

# ── 1. Your Mac ───────────────────────────────────────────────────────────────
step "Checking your Mac"
[ "$(uname -s)" = "Darwin" ] || fail "This folder is for macOS. On Linux/Windows see https://ollama.com/download"

macos_version="$(sw_vers -productVersion)"
macos_major="${macos_version%%.*}"
if [ "$macos_major" -lt "$MIN_MACOS_MAJOR" ]; then
  fail "macOS $macos_version found. Ollama needs macOS $MIN_MACOS_MAJOR (Sonoma) or newer."
fi
ok "macOS $macos_version"

arch="$(uname -m)"
if [ "$arch" = "arm64" ]; then
  ok "Apple Silicon ($(chip_name)) — Ollama can use the GPU"
else
  warn "Intel Mac ($arch) — Ollama runs on the CPU only, so expect slower answers"
fi

ram="$(ram_gb)"
ok "${ram} GB of memory"
if [ "$ram" -le 8 ] && [ -z "$MODEL_FROM_USER" ]; then
  MODEL="$SMALL_MODEL"
  warn "8 GB or less: using the smaller $MODEL (set MODEL=... to override)"
fi

# ── 2. Ollama installed? ─────────────────────────────────────────────────────
step "Checking for Ollama"
if ! command -v ollama >/dev/null 2>&1; then
  warn "Ollama isn't installed yet."
  if command -v brew >/dev/null 2>&1; then
    if [ "$ASSUME_YES" -eq 0 ]; then
      read -r -p "  Install it now with Homebrew (brew install --cask ollama-app)? [y/N] " reply
      [[ "$reply" =~ ^[Yy]$ ]] || fail "Install it from https://ollama.com/download/mac, then run ./setup.sh again."
    fi
    brew install --cask ollama-app
  else
    echo "  Download the Mac app from https://ollama.com/download/mac,"
    echo "  drag it to Applications, open it once, then run ./setup.sh again."
    exit 1
  fi
fi

# ── 3. Ollama running? ───────────────────────────────────────────────────────
step "Starting Ollama"
if ! server_up; then
  open -a Ollama 2>/dev/null || true
  printf '  waiting for the Ollama server'
  for _ in $(seq 1 30); do
    server_up && break
    printf '.'; sleep 1
  done
  echo
fi
server_up || fail "Ollama isn't answering at $OLLAMA_URL. Open the Ollama app (or run: ollama serve) and try again."
command -v ollama >/dev/null 2>&1 || fail "Ollama is running, but the 'ollama' command isn't on your PATH. Open the app once; it offers to add it to /usr/local/bin."

version="$(server_version)"
ok "Ollama $version is running at $OLLAMA_URL"
if [ "$version" != "$TESTED_OLLAMA_VERSION" ]; then
  warn "This folder was tested with Ollama $TESTED_OLLAMA_VERSION. Newer versions usually work; if something differs, check TESTED.md."
fi

# ── 4. The model ─────────────────────────────────────────────────────────────
step "Downloading $MODEL"
if model_installed "$MODEL"; then
  ok "$MODEL is already on your Mac"
else
  ollama pull "$MODEL"
  ok "$MODEL downloaded"
fi

# ── Done ─────────────────────────────────────────────────────────────────────
step "All set"
cat <<EOF
  Chat with it:       ollama run $MODEL
  Leave the chat:     /bye
  Measure & verify:   MODEL=$MODEL ./verify.sh
  Offline proof:      turn off Wi-Fi, then  MODEL=$MODEL ./verify.sh --offline
EOF
