#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

FN=ledger-month-close
meta="$(mktemp)"; body="$(mktemp)"
trap 'rm -f "$meta" "$body"' EXIT

if ! aws_local lambda get-function-configuration --function-name "$FN" >"$meta" 2>&1; then
  echo "$FN is gone. This mission is about fixing it, not replacing it."
  exit 1
fi
runtime="$(jq -r '.Runtime' "$meta")"
handler="$(jq -r '.Handler' "$meta")"

payload='{"entries":[{"account":"4000","amount_cents":12500,"kind":"credit"},{"account":"4010","amount_cents":4000,"kind":"debit"},{"account":"4020","amount_cents":0,"kind":"void"},{"account":"4000","amount_cents":500,"kind":"credit"}]}'
aws_local lambda invoke --function-name "$FN" --cli-binary-format raw-in-base64-out \
  --payload "$payload" "$body" >"$meta" 2>&1 || { echo "Invoke call itself failed: $(tail -1 "$meta")"; exit 1; }

if jq -e '.FunctionError' "$meta" >/dev/null 2>&1; then
  msg="$(jq -r '.errorMessage // empty' "$body")"
  type="$(jq -r '.errorType // empty' "$body")"
  echo "The close job still fails on runtime '$runtime' ($type): $msg"
  case "$type" in
    Runtime.UserCodeSyntaxError) echo "That runtime starts, but it cannot parse this source. Newer syntax needs a newer interpreter." ;;
    Lambda.InitError) echo "Lambda cannot even start a container for that runtime." ;;
  esac
  exit 1
fi

net="$(jq -r '.net' "$body")"
if [ "$net" != "9000" ] || [ "$(jq -r '.voided' "$body")" != "1" ]; then
  echo "Function ran on $runtime but returned unexpected totals: $(head -c 200 "$body")"
  exit 1
fi
if [ "$handler" != "month_close.handler" ]; then
  echo "The handler was changed to $handler. Only the runtime should need to change."
  exit 1
fi

echo "Month-end close works on $runtime: credits 13000, debits 4000, net 9000."
