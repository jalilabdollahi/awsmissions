#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

res="$(mktemp)"; hdr="$(mktemp)"
trap 'rm -f "$res" "$hdr"' EXIT

mem="$(aws_local lambda get-function-configuration --function-name tile-stitcher --query MemorySize --output text)"
if [ "$mem" -gt 1024 ]; then
  echo "Memory is set to ${mem} MB. Finance capped this function at 1024 MB: find the smaller setting that works."
  exit 1
fi

aws_local lambda invoke --function-name tile-stitcher --cli-binary-format raw-in-base64-out \
  --payload '{"tiles_per_side":16}' "$res" >"$hdr" 2>&1 || { echo "Invoke failed: $(tail -1 "$hdr")"; exit 1; }

if jq -e '.FunctionError' "$hdr" >/dev/null 2>&1; then
  echo "The 16x16 export still crashes at ${mem} MB: $(jq -r '.errorMessage' "$res" | head -c 200)"
  echo "Exit status 137 means the process was killed for exceeding its memory limit."
  exit 1
fi
if [ "$(jq -r '.canvas_mb' "$res")" != "256" ]; then
  echo "Unexpected response: $(head -c 200 "$res")"
  exit 1
fi

echo "The 256 MB canvas stitches fine with ${mem} MB configured."
