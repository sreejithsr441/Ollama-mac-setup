#!/usr/bin/env python3
"""Chat with your local Ollama model from Python — standard library only.

Usage:  python3 examples/chat.py "Your question here"
The answer streams word by word, the same way it does in Terminal.
"""
import json
import os
import sys
import urllib.request

MODEL = os.environ.get("MODEL", "gemma4:e2b")
QUESTION = sys.argv[1] if len(sys.argv) > 1 else "Why is the sky blue? Answer in one sentence."

request = urllib.request.Request(
    "http://localhost:11434/api/chat",
    data=json.dumps({
        "model": MODEL,
        "messages": [{"role": "user", "content": QUESTION}],
        "stream": True,
    }).encode(),
    headers={"Content-Type": "application/json"},
)

with urllib.request.urlopen(request) as response:
    for line in response:            # one JSON object per line
        chunk = json.loads(line)
        print(chunk.get("message", {}).get("content", ""), end="", flush=True)
        if chunk.get("done"):
            print()
