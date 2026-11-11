#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

API_ID="$(aws_local apigatewayv2 get-apis --query "Items[?Name=='fernwood-quotes'].ApiId | [0]" --output text 2>/dev/null || true)"
if [ -z "$API_ID" ] || [ "$API_ID" = "None" ]; then
  echo "fernwood-quotes does not exist."
  exit 1
fi
base="$AWS_ENDPOINT_URL/restapis/$API_ID/prod/_user_request_/quotes"
body="$(mktemp)"
trap 'rm -f "$body"' EXIT

code="$(curl -s --max-time 60 -o "$body" -w '%{http_code}' "$base/eu?weight=12" || true)"
if [ "$code" = "500" ]; then
  echo "GET /quotes/eu?weight=12 returns 500. The function itself is healthy; does the event it receives look like the one it was written for?"
  exit 1
fi
if [ "$code" != "200" ]; then
  echo "GET /quotes/eu?weight=12 returned HTTP $code: $(head -c 150 "$body")"
  exit 1
fi
if ! python3 -c '
import json, sys
d = json.load(open(sys.argv[1]))
assert d["zone"] == "eu" and d["weight_kg"] == 12 and d["price_eur"] == 22.8, d
assert d["via"] == "GET" and d["path"].endswith("/quotes/eu"), d
' "$body" 2>/dev/null; then
  echo "The call succeeded but the quote is wrong: $(head -c 200 "$body")"
  exit 1
fi
code="$(curl -s --max-time 60 -o "$body" -w '%{http_code}' "$base/apac?weight=5" || true)"
if [ "$code" != "200" ] || ! grep -q '"price_eur": 17.0' "$body"; then
  echo "A second quote (apac, 5 kg) should cost 17.0 (HTTP $code: $(head -c 150 "$body"))."
  exit 1
fi
echo "Quotes are priced correctly for different zones and weights."
