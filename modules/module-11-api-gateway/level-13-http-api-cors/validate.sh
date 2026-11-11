#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

ORIGIN="https://boards.maple.example"
API_ID="$(aws_local apigatewayv2 get-apis --query "Items[?Name=='mapleboard-http'].ApiId | [0]" --output text 2>/dev/null || true)"
if [ -z "$API_ID" ] || [ "$API_ID" = "None" ]; then
  echo "The HTTP API mapleboard-http does not exist."
  exit 1
fi
url="$AWS_ENDPOINT_URL/restapis/$API_ID/prod/_user_request_/boards"
hdrs="$(mktemp)"; body="$(mktemp)"
trap 'rm -f "$hdrs" "$body"' EXIT
header() { { grep -i "^$1:" "$hdrs" || true; } | head -1 | sed 's/^[^:]*:[[:space:]]*//' | tr -d '\r'; }

preflight() {
  : > "$hdrs"
  curl -s --max-time 60 -D "$hdrs" -o "$body" -w '%{http_code}' -X OPTIONS \
    -H "Origin: $1" -H "Access-Control-Request-Method: POST" \
    -H "Access-Control-Request-Headers: content-type" "$url" || true
}

code="$(preflight "$ORIGIN")"
if [ "$code" != "204" ] && [ "$code" != "200" ]; then
  echo "The preflight from $ORIGIN returns HTTP $code ($(head -c 100 "$body"))."
  exit 1
fi
origin="$(header access-control-allow-origin)"
if [ -z "$origin" ]; then
  echo "The preflight response has no Access-Control-Allow-Origin header: CORS is not configured on this API."
  exit 1
fi
if [ "$origin" = "*" ]; then
  echo "The API answers '*' for the origin. The app sends cookies, and browsers refuse a wildcard together with credentials. Name the origin explicitly."
  exit 1
fi
if [ "$origin" != "$ORIGIN" ]; then
  echo "Access-Control-Allow-Origin is '$origin', expected $ORIGIN."
  exit 1
fi
methods="$(header access-control-allow-methods)"
for m in GET POST; do
  case ",$methods," in *"$m"*) ;; *) echo "Access-Control-Allow-Methods ('$methods') misses $m."; exit 1 ;; esac
done
allowed_headers="$(header access-control-allow-headers | tr 'A-Z' 'a-z')"
case "$allowed_headers" in *content-type*) ;; *) echo "Access-Control-Allow-Headers ('$allowed_headers') misses Content-Type."; exit 1 ;; esac
creds="$(header access-control-allow-credentials | tr 'A-Z' 'a-z')"
if [ "$creds" != "true" ]; then
  echo "The preflight does not allow credentials (Access-Control-Allow-Credentials: true). The app sends cookies."
  exit 1
fi

# Actual request: data still flows and carries the headers.
: > "$hdrs"
code="$(curl -s --max-time 60 -D "$hdrs" -o "$body" -w '%{http_code}' -H "Origin: $ORIGIN" "$url" || true)"
if [ "$code" != "200" ] || ! grep -q 'Sprint 41' "$body"; then
  echo "GET /boards stopped returning boards (HTTP $code)."
  exit 1
fi
if [ "$(header access-control-allow-origin)" != "$ORIGIN" ]; then
  echo "The real GET response lacks Access-Control-Allow-Origin: $ORIGIN."
  exit 1
fi

# Other origins must not be approved.
code="$(preflight https://evil.example)"
if [ -n "$(header access-control-allow-origin)" ]; then
  echo "Origin https://evil.example is approved too ('$(header access-control-allow-origin)'). Only the Mapleboard front end should be."
  exit 1
fi
echo "CORS is limited to https://boards.maple.example, with credentials, for GET and POST."
