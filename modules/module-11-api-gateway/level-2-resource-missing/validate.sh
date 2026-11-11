#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

API_ID="$(aws_local apigateway get-rest-apis --query "items[?name=='quillnote-api'].id | [0]" --output text 2>/dev/null || true)"
if [ -z "$API_ID" ] || [ "$API_ID" = "None" ]; then
  echo "quillnote-api is gone. Fix the existing API instead of replacing it."
  exit 1
fi
base="$AWS_ENDPOINT_URL/restapis/$API_ID/v1/_user_request_"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

code="$(curl -s --max-time 60 -o "$tmp" -w '%{http_code}' "$base/notes" || true)"
if [ "$code" != "200" ]; then
  echo "GET /notes broke (HTTP $code). The list route has to keep working."
  exit 1
fi

code="$(curl -s --max-time 60 -o "$tmp" -w '%{http_code}' "$base/notes/n-204" || true)"
if [ "$code" = "403" ] || [ "$code" = "404" ]; then
  echo "GET /notes/n-204 returns $code: API Gateway has no route for that path."
  exit 1
fi
if [ "$code" = "400" ]; then
  echo "The route exists and reaches the function, but the function says: $(head -c 120 "$tmp"). It reads the id from the path parameter noteId, so the path segment must be named exactly that."
  exit 1
fi
if [ "$code" != "200" ]; then
  echo "GET /notes/n-204 returned HTTP $code: $(head -c 200 "$tmp")"
  exit 1
fi
if ! grep -q '"Buy oat milk"' "$tmp"; then
  echo "GET /notes/n-204 answered 200 but not with the note: $(head -c 200 "$tmp")"
  exit 1
fi
code="$(curl -s --max-time 60 -o "$tmp" -w '%{http_code}' "$base/notes/n-999" || true)"
if [ "$code" != "404" ] || ! grep -q "no such note" "$tmp"; then
  echo "An unknown note id should reach the function and come back as its own 404 ('no such note'); got HTTP $code: $(head -c 120 "$tmp")"
  exit 1
fi
echo "Single notes resolve through /notes/{noteId}, the list still works."
