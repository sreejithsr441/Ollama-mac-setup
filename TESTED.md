# Tested setups

Every number in the video comes from a row in this table. Add a row by running `./verify.sh` (and `./verify.sh --offline` with the Wi-Fi off) and pasting the line it prints.

Last full test from a fresh clone: <!-- TODO: date -->

| Date | Mac | Chip | Memory | macOS | Ollama | Model | Writing speed | Network |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| <!-- paste verify.sh output rows here --> | | | | | | | | |

## Notes

- Writing speed = tokens per second while the model writes its answer (`eval_count ÷ eval_duration` from Ollama's API), median of the timed runs. The first run that loads the model is not counted.
- Prompt and settings: see `verify.sh` (temperature 0, up to 200 tokens).
- `setup.sh` warns if your Ollama version differs from `TESTED_OLLAMA_VERSION` in `config.sh`. Update both after re-testing.
