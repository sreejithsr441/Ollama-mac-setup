# shellcheck shell=bash
# Helpers shared by setup.sh and verify.sh. Not meant to be run directly.

if [ -t 1 ]; then
  BOLD=$'\033[1m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; RESET=$'\033[0m'
else
  BOLD=""; GREEN=""; YELLOW=""; RED=""; RESET=""
fi

step() { printf '\n%s==> %s%s\n' "$BOLD" "$*" "$RESET"; }
ok()   { printf '%s  ✓ %s%s\n' "$GREEN" "$*" "$RESET"; }
warn() { printf '%s  ! %s%s\n' "$YELLOW" "$*" "$RESET"; }
fail() { printf '%s  ✗ %s%s\n' "$RED" "$*" "$RESET" >&2; exit 1; }

# json_get '<json>' 'path.to.field'  -> prints the value, or nothing if missing.
# Uses jq when installed, otherwise macOS's built-in JavaScript (osascript),
# so nothing extra needs to be installed.
json_get() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$1" | jq -r ".$2 // empty"
  elif command -v osascript >/dev/null 2>&1; then
    osascript -l JavaScript -e '
      function run(argv) {
        var v = argv[1].split(".").reduce(function (o, k) {
          return (o === null || o === undefined) ? undefined : o[k];
        }, JSON.parse(argv[0]));
        return (v === undefined || v === null) ? "" : String(v);
      }' "$1" "$2"
  else
    fail "Need jq or osascript to read JSON (install jq with: brew install jq)"
  fi
}

# Is the Ollama server answering?
server_up() { curl -fsS --max-time 2 "$OLLAMA_URL/api/version" >/dev/null 2>&1; }

# Version reported by the running server, e.g. 0.35.1
server_version() { json_get "$(curl -fsS --max-time 2 "$OLLAMA_URL/api/version")" version; }

# Is MODEL already downloaded? Untagged names are stored as name:latest.
model_installed() {
  local want="$1"
  [[ "$want" == *:* ]] || want="$want:latest"
  ollama ls 2>/dev/null | awk 'NR>1 {print $1}' | grep -Fxq "$want"
}

ram_gb() { echo $(( $(sysctl -n hw.memsize) / 1073741824 )); }
chip_name() { sysctl -n machdep.cpu.brand_string 2>/dev/null || uname -m; }
