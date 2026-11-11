#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

res="$(mktemp)"; hdr="$(mktemp)"
trap 'rm -f "$res" "$hdr"' EXIT

timeout_s="$(aws_local lambda get-function-configuration --function-name statement-renderer --query Timeout --output text)"
if [ "$timeout_s" -gt 29 ]; then
  echo "The timeout is ${timeout_s}s. The portal's HTTP API gives up after 29s, so anything longer than that just hides failures from callers."
  exit 1
fi

# The real test: render a quarterly statement (12 pages, about 7 seconds).
aws_local lambda invoke --function-name statement-renderer --cli-binary-format raw-in-base64-out \
  --payload '{"customer":"ACME-0042","pages":12}' "$res" >"$hdr" 2>&1 || {
    echo "Invoke failed: $(tail -1 "$hdr")"; exit 1; }

if jq -e '.FunctionError' "$hdr" >/dev/null 2>&1; then
  echo "The 12-page statement still fails with a ${timeout_s}s timeout: $(jq -r '.errorMessage' "$res" | head -c 200)"
  echo "A page takes about 600 ms; work out how long twelve of them need."
  exit 1
fi
if [ "$(jq -r '.pages_rendered' "$res")" != "12" ]; then
  echo "Unexpected response: $(head -c 200 "$res")"
  exit 1
fi

echo "Quarterly statements render in full. Timeout is ${timeout_s}s, within the portal's 29s limit."
