#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

args=()

for arg in "$@"; do
  case "$arg" in
    --reset|--reset-progress)
      rm -f progress.json
      ;;
    *)
      args+=("$arg")
      ;;
  esac
done

source .venv/bin/activate 2>/dev/null || true
python3 -m engine.engine "${args[@]}"
