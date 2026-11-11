#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

API_ID="$(aws_local apigateway get-rest-apis --query "items[?name=='brewbook-api'].id | [0]" --output text 2>/dev/null || true)"
if [ -z "$API_ID" ] || [ "$API_ID" = "None" ]; then
  echo "brewbook-api is gone."
  exit 1
fi
base="$AWS_ENDPOINT_URL/restapis/$API_ID/test/_user_request_/brews"
out="$(mktemp)"
trap 'rm -f "$out"' EXIT

code="$(curl -s --max-time 60 -o "$out" -w '%{http_code}' "$base?roast=dark" || true)"
if [ "$code" != "200" ]; then
  echo "GET /brews?roast=dark returned HTTP $code ($(head -c 120 "$out")). The method has nothing behind it, or something that cannot answer."
  exit 1
fi
if ! python3 -c '
import json, sys
d = json.load(open(sys.argv[1]))
assert d["ids"] == ["b-11", "b-14"], d
' "$out" 2>/dev/null; then
  echo "The call succeeded but did not carry the roast to the search function: $(head -c 200 "$out")"
  echo "The function reads the query string from the proxy event."
  exit 1
fi
code="$(curl -s --max-time 60 -o "$out" -w '%{http_code}' "$base?roast=light" || true)"
if [ "$code" != "200" ] || ! grep -q '"b-2"' "$out" || grep -q 'b-11' "$out"; then
  echo "?roast=light should return only b-2 (HTTP $code, $(head -c 120 "$out"))."
  exit 1
fi
echo "Search works end to end: dark and light roasts come from brewbook-search."
