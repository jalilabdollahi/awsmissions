#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

res="$(mktemp)"; hdr="$(mktemp)"
trap 'rm -f "$res" "$hdr"' EXIT

aws_local lambda invoke --function-name fx-rate-lookup --cli-binary-format raw-in-base64-out \
  --payload '{"pair":"EURUSD","amount":2500}' "$res" >"$hdr" 2>&1 || {
    echo "Invoke failed: $(tail -1 "$hdr")"; exit 1; }

if jq -e '.FunctionError' "$hdr" >/dev/null 2>&1; then
  etype="$(jq -r '.errorType' "$res")"
  emsg="$(jq -r '.errorMessage' "$res" | head -c 220)"
  echo "fx-rate-lookup still fails ($etype): $emsg"
  case "$etype" in
    KeyError) echo "The function asked for a setting that is not in its environment." ;;
    *AccessDenied*|*ClientError*) echo "The setting now exists, but the table it names is not one this function's role may read." ;;
  esac
  exit 1
fi

converted="$(jq -r '.converted // empty' "$res")"
if [ "$converted" != "2718.3750" ]; then
  if [ "$converted" = "2718.38" ]; then
    echo "The conversion works, but only with two decimals ($converted). FX_PRECISION=4 used to be configured; it was lost when you replaced the environment."
  else
    echo "Got '$converted' (response: $(head -c 150 "$res")), expected 2718.3750 using the production rate."
  fi
  exit 1
fi

echo "fx-rate-lookup converts at the production rate with four decimals: 2500 EUR = 2718.3750 USD."
