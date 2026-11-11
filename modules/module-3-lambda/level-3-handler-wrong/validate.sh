#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

res="$(mktemp)"; hdr="$(mktemp)"
trap 'rm -f "$res" "$hdr"' EXIT

cfg="$(aws_local lambda get-function-configuration --function-name webhook-relay 2>&1)" || {
  echo "webhook-relay no longer exists: $(printf '%s' "$cfg" | tail -1)"; exit 1; }
if [ "$(printf '%s' "$cfg" | jq -r '.CodeSize')" -lt 100 ]; then
  echo "The deployed package looks empty. Do not redeploy it; only the handler setting is wrong."; exit 1
fi

order='{"id":"PO-2231","sku":"TENT-4P","qty":2}'
event="{\"partner\":\"northtrail\",\"order\":${order}}"
aws_local lambda invoke --function-name webhook-relay --cli-binary-format raw-in-base64-out \
  --payload "$event" "$res" >"$hdr" 2>&1 || { echo "Invoke failed: $(tail -1 "$hdr")"; exit 1; }

if jq -e '.FunctionError' "$hdr" >/dev/null 2>&1; then
  echo "Invocation still fails: $(jq -r '[.errorType,.errorMessage]|join(": ")' "$res" | head -c 300)"
  exit 1
fi

want="$(python3 - <<'PY'
import hmac, hashlib, json
body = json.dumps({"id": "PO-2231", "sku": "TENT-4P", "qty": 2}, separators=(",", ":"))
print(hmac.new(b"pinecrest-partner-key-7f3a", body.encode(), hashlib.sha256).hexdigest())
PY
)"
got="$(jq -r '.signature // empty' "$res")"
if [ -z "$got" ]; then
  echo "The function runs now, but it returned $(head -c 120 "$res") instead of a signed webhook. Another exported function is answering; check which one is the real entry point."
  exit 1
fi
if [ "$got" != "$want" ] || [ "$(jq -r '.statusCode' "$res")" != "202" ]; then
  echo "A signature came back but it does not match the partner's expectation."
  exit 1
fi

echo "webhook-relay signs and relays orders again."
