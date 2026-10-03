#!/usr/bin/env bash
# The one API call from the video (chapter "Use your local AI from code").
# Usage: ./examples/chat.sh "Your question here"
set -euo pipefail
MODEL="${MODEL:-gemma4:e2b}"
QUESTION="${1:-Why is the sky blue? Answer in one sentence.}"
# Escape backslashes and quotes so the question is valid JSON.
QUESTION="$(printf '%s' "$QUESTION" | sed 's/\\/\\\\/g; s/"/\\"/g')"

curl -s http://localhost:11434/api/chat -d "{
  \"model\": \"$MODEL\",
  \"messages\": [{ \"role\": \"user\", \"content\": \"$QUESTION\" }],
  \"stream\": false
}"
echo
