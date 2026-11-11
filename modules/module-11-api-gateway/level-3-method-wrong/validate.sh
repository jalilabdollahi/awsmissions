#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

API_ID="$(aws_local apigateway get-rest-apis --query "items[?name=='parcelpoint-help'].id | [0]" --output text 2>/dev/null || true)"
if [ -z "$API_ID" ] || [ "$API_ID" = "None" ]; then
  echo "parcelpoint-help does not exist any more."
  exit 1
fi
url="$AWS_ENDPOINT_URL/restapis/$API_ID/prod/_user_request_/tickets"
out="$(mktemp)"
trap 'rm -f "$out"' EXIT

code="$(curl -s --max-time 60 -o "$out" -w '%{http_code}' "$url" || true)"
if [ "$code" != "200" ] || ! grep -q '"via": "list"' "$out"; then
  echo "GET /tickets must still be served by the list function (HTTP $code, $(head -c 100 "$out"))."
  exit 1
fi

code="$(curl -s --max-time 60 -o "$out" -w '%{http_code}' -X POST \
  -H 'Content-Type: application/json' -d '{"title":"Box arrived crushed"}' "$url" || true)"
case "$code" in
  403) echo "POST /tickets still answers 403 (Missing Authentication Token): there is no POST method on /tickets."; exit 1 ;;
  201) ;;
  *) echo "POST /tickets returned HTTP $code: $(head -c 200 "$out")"; exit 1 ;;
esac
if ! grep -q '"via": "create"' "$out" || ! grep -q 'Box arrived crushed' "$out"; then
  echo "POST /tickets answered 201 but not from the create function with the title echoed back: $(head -c 200 "$out")"
  exit 1
fi
code="$(curl -s --max-time 60 -o "$out" -w '%{http_code}' -X POST -H 'Content-Type: application/json' -d '{}' "$url" || true)"
if [ "$code" != "400" ]; then
  echo "A POST without a title should be rejected by the function with 400, got $code."
  exit 1
fi
echo "Tickets can be filed (POST, 201) and listed (GET)."
