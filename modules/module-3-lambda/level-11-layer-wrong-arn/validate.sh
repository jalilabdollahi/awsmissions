#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

res="$(mktemp)"; hdr="$(mktemp)"
trap 'rm -f "$res" "$hdr"' EXIT

aws_local lambda invoke --function-name txn-scorer --cli-binary-format raw-in-base64-out \
  --payload '{"txn":{"amount":950,"country":"BR","txns_last_hour":7}}' "$res" >"$hdr" 2>&1 || {
    echo "Invoke failed: $(tail -1 "$hdr")"; exit 1; }

if jq -e '.FunctionError' "$hdr" >/dev/null 2>&1; then
  msg="$(jq -r '.errorMessage' "$res" | head -c 260)"
  echo "txn-scorer still crashes during start-up: $msg"
  case "$msg" in
    *tracekit*) echo "A layer the function relies on is no longer attached." ;;
    *riskkit*|*velocity*) echo "The attached riskkit-core layer does not contain what the code imports." ;;
  esac
  exit 1
fi

score="$(jq -r '.score' "$res")"
trace="$(jq -r '.trace // empty' "$res")"
if [ "$score" != "80" ]; then
  echo "The function runs but scored the sample transaction $score instead of 80."
  exit 1
fi
case "$trace" in tk-*) ;; *) echo "Scoring works but the trace id is missing: tracekit-logging seems to be detached."; exit 1 ;; esac

echo "txn-scorer applies the 2024 ruleset (score 80, decision review) with tracing intact."
