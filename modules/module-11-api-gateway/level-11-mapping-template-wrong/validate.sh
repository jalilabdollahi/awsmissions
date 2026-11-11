#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

API_ID="$(aws_local apigateway get-rest-apis --query "items[?name=='crateful-api'].id | [0]" --output text 2>/dev/null || true)"
if [ -z "$API_ID" ] || [ "$API_ID" = "None" ]; then
  echo "crateful-api does not exist."
  exit 1
fi
url="$AWS_ENDPOINT_URL/restapis/$API_ID/live/_user_request_/reservations"
out="$(mktemp)"
trap 'rm -f "$out"' EXIT
post() {
  curl -s --max-time 60 -o "$out" -w '%{http_code}' -X POST -H 'Content-Type: application/json' -d "$1" "$url" || true
}

code="$(post '{"productCode":"SKU-77","quantity":4,"note":"gift wrap"}')"
if [ "$code" != "200" ]; then
  echo "POST /reservations for SKU-77 returned HTTP $code: $(head -c 200 "$out")"
  echo "That message comes from the function. Look at what the template hands it."
  exit 1
fi
if ! python3 -c '
import json, sys
d = json.load(open(sys.argv[1]))
assert d["reserved"] == "SKU-77", d
assert d["units"] == 4 and isinstance(d["units"], int), d
assert d["note"] == "gift wrap", d
' "$out" 2>/dev/null; then
  echo "The function answered 200 but did not receive the right values: $(head -c 200 "$out")"
  exit 1
fi

# Generality and quoting: another product, other numbers, and a note with double quotes.
code="$(post '{"productCode":"CRATE-9","quantity":12,"note":"say \"hello\" to Max"}')"
if [ "$code" != "200" ] || ! python3 -c '
import json, sys
d = json.load(open(sys.argv[1]))
assert d["reserved"] == "CRATE-9" and d["units"] == 12, d
assert d["note"] == "say \"hello\" to Max", d
' "$out" 2>/dev/null; then
  echo "A second reservation misbehaves (HTTP $code: $(head -c 200 "$out")). Is the template hard-coded, or does it break on quotes in the note? Free text must be escaped."
  exit 1
fi
echo "Partner bodies are translated correctly, including awkward notes."
