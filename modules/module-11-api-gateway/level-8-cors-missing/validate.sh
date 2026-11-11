#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

ORIGIN="https://app.zestlist.example"
API_ID="$(aws_local apigateway get-rest-apis --query "items[?name=='zestlist-api'].id | [0]" --output text 2>/dev/null || true)"
if [ -z "$API_ID" ] || [ "$API_ID" = "None" ]; then
  echo "zestlist-api does not exist."
  exit 1
fi
url="$AWS_ENDPOINT_URL/restapis/$API_ID/web/_user_request_/tasks"
hdrs="$(mktemp)"; body="$(mktemp)"
trap 'rm -f "$hdrs" "$body"' EXIT
header() { { grep -i "^$1:" "$hdrs" || true; } | head -1 | sed 's/^[^:]*:[[:space:]]*//' | tr -d '\r'; }

# 1. The data call itself must still work (and be JSON from the function).
code="$(curl -s --max-time 60 -D "$hdrs" -o "$body" -w '%{http_code}' -H "Origin: $ORIGIN" "$url" || true)"
if [ "$code" != "200" ] || ! grep -q 'Water the ferns' "$body"; then
  echo "GET /tasks no longer returns the tasks (HTTP $code: $(head -c 120 "$body"))."
  exit 1
fi
get_origin="$(header access-control-allow-origin)"

# 2. Preflight, exactly what a browser sends before an authenticated JSON request.
code="$(curl -s --max-time 60 -D "$hdrs" -o "$body" -w '%{http_code}' -X OPTIONS \
  -H "Origin: $ORIGIN" -H 'Access-Control-Request-Method: POST' \
  -H 'Access-Control-Request-Headers: content-type,authorization' "$url" || true)"
case "$code" in
  200|204) ;;
  403) echo "The preflight (OPTIONS /tasks) answers 403: there is no OPTIONS method on /tasks."; exit 1 ;;
  *) echo "The preflight returned HTTP $code ($(head -c 120 "$body"))."; exit 1 ;;
esac
pre_origin="$(header access-control-allow-origin)"
pre_methods="$(header access-control-allow-methods)"
pre_headers="$(header access-control-allow-headers | tr 'A-Z' 'a-z')"

if [ -z "$pre_origin" ]; then
  echo "The preflight answers $code but has no Access-Control-Allow-Origin header. If you mapped it, check that the value is wrapped in single quotes inside double quotes (a static value), otherwise API Gateway looks for a header named like the origin."
  exit 1
fi
if [ "$pre_origin" = "*" ]; then
  echo "The preflight allows every origin ('*'). Requests with credentials are rejected by browsers for a wildcard; return the exact origin $ORIGIN."
  exit 1
fi
if [ "$pre_origin" != "$ORIGIN" ]; then
  echo "The preflight allows origin '$pre_origin' instead of $ORIGIN."
  exit 1
fi
case ",$pre_methods," in *GET*) ;; *) echo "Access-Control-Allow-Methods is '$pre_methods' and misses GET."; exit 1 ;; esac
case ",$pre_methods," in *POST*) ;; *) echo "Access-Control-Allow-Methods is '$pre_methods' and misses POST."; exit 1 ;; esac
case "$pre_headers" in *authorization*) ;; *) echo "Access-Control-Allow-Headers ('$pre_headers') misses Authorization, which the app sends."; exit 1 ;; esac
case "$pre_headers" in *content-type*) ;; *) echo "Access-Control-Allow-Headers ('$pre_headers') misses Content-Type."; exit 1 ;; esac

# 3. The actual response needs the header too, or the browser hides the body.
if [ "$get_origin" != "$ORIGIN" ]; then
  echo "The preflight is fine, but the real GET /tasks response has Access-Control-Allow-Origin '$get_origin'. Browsers check the header on the actual response too."
  exit 1
fi
echo "Preflight and data response both allow exactly $ORIGIN. The browser will accept the call."
