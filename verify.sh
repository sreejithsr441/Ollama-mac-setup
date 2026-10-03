#!/usr/bin/env bash
# Ring Zero — verify the local model works and measure its speed.
#
# Sends the same prompt through Ollama's local API a few times, reports
# tokens per second (median), shows `ollama ps`, and prints a block you
# can paste into TESTED.md.
#
# Usage:
#   ./verify.sh                 # 3 timed runs
#   ./verify.sh --runs 5
#   ./verify.sh --offline       # also confirm the internet is really off
#   MODEL=gemma4:12b-mlx ./verify.sh
set -euo pipefail

cd "$(dirname "$0")"
# shellcheck source=config.sh
source ./config.sh
# shellcheck source=lib.sh
source ./lib.sh

RUNS=3
OFFLINE=0
PROMPT="${PROMPT:-In two sentences, explain why running an AI model on your own computer keeps your data private.}"

while [ $# -gt 0 ]; do
  case "$1" in
    --runs) RUNS="${2:?--runs needs a number}"; shift 2 ;;
    --offline) OFFLINE=1; shift ;;
    -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
    *) fail "Unknown option: $1 (try --help)" ;;
  esac
done
[[ "$RUNS" =~ ^[1-9][0-9]*$ ]] || fail "--runs must be a positive number"

# ── 1. Server and model ──────────────────────────────────────────────────────
step "Checking Ollama"
server_up || fail "Ollama isn't answering at $OLLAMA_URL. Open the Ollama app or run: ollama serve"
version="$(server_version)"
ok "Ollama $version at $OLLAMA_URL"
model_installed "$MODEL" || fail "$MODEL isn't downloaded. Run: ./setup.sh   (or: ollama pull $MODEL)"
ok "$MODEL is installed"

# ── 2. Offline check (for the Wi-Fi-off demo) ────────────────────────────────
if [ "$OFFLINE" -eq 1 ]; then
  step "Checking the internet is off"
  if curl -fsS --max-time 4 -o /dev/null https://ollama.com 2>/dev/null; then
    fail "You're still online (ollama.com answered). Turn off Wi-Fi and run this again."
  fi
  ok "No internet connection — everything below runs on this Mac"
fi

# ── 3. Timed runs ────────────────────────────────────────────────────────────
generate() {
  local body prompt
  prompt="$(printf '%s' "$PROMPT" | sed 's/\\/\\\\/g; s/"/\\"/g')"
  body=$(printf '{"model":"%s","prompt":"%s","stream":false,"options":{"temperature":0,"num_predict":200}}' "$MODEL" "$prompt")
  curl -fsS --max-time 600 "$OLLAMA_URL/api/generate" -H 'Content-Type: application/json' -d "$body"
}

step "Loading $MODEL (warm-up, not timed)"
warm="$(generate)" || fail "The model didn't answer. Run: ollama run $MODEL  to see the error."
load_ns="$(json_get "$warm" load_duration)"
ok "Loaded in $(awk -v ns="${load_ns:-0}" 'BEGIN{printf "%.1f", ns/1e9}') s"

step "Timing $RUNS runs"
speeds=()
answer=""
for i in $(seq 1 "$RUNS"); do
  r="$(generate)"
  count="$(json_get "$r" eval_count)"
  dur="$(json_get "$r" eval_duration)"
  pcount="$(json_get "$r" prompt_eval_count)"
  pdur="$(json_get "$r" prompt_eval_duration)"
  answer="$(json_get "$r" response)"
  [ -n "$count" ] && [ -n "$dur" ] && [ "$dur" -gt 0 ] || fail "Run $i returned no timing data."
  tps="$(awk -v c="$count" -v d="$dur" 'BEGIN{printf "%.1f", c/(d/1e9)}')"
  pps="$(awk -v c="${pcount:-0}" -v d="${pdur:-0}" 'BEGIN{ if (d>0) printf "%.0f", c/(d/1e9); else printf "n/a" }')"
  speeds+=("$tps")
  printf '  run %d: %s tokens/s writing (%s tokens) · %s tokens/s reading the prompt\n' "$i" "$tps" "$count" "$pps"
done

median="$(printf '%s\n' "${speeds[@]}" | sort -n | awk '{a[NR]=$1} END{ if (NR%2) print a[(NR+1)/2]; else printf "%.1f\n", (a[NR/2]+a[NR/2+1])/2 }')"
ok "Median: $median tokens/s"

step "The model's answer"
printf '%s\n' "$answer" | fold -s -w 80 | sed 's/^/  /'

# ── 4. Where is it running? ──────────────────────────────────────────────────
step "ollama ps  (PROCESSOR should say 100% GPU on Apple Silicon)"
ollama ps | sed 's/^/  /'
if ! ollama ps | grep -q '100% GPU'; then
  warn "Not fully on the GPU. The model may be too big for your memory — try a smaller one."
fi

# ── 5. For TESTED.md ─────────────────────────────────────────────────────────
step "Paste this into TESTED.md"
cat <<EOF
| $(date +%Y-%m-%d) | $(sysctl -n hw.model 2>/dev/null || echo Mac) | $(chip_name) | $(ram_gb) GB | macOS $(sw_vers -productVersion) | Ollama $version | $MODEL | $median tok/s (median of $RUNS) | $([ "$OFFLINE" -eq 1 ] && echo "Wi-Fi off" || echo "online") |
EOF
