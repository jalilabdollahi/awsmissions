#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

API_ID="$(aws_local apigatewayv2 get-apis --query "Items[?Name=='pinecone-metrics'].ApiId | [0]" --output text 2>/dev/null || true)"
if [ -z "$API_ID" ] || [ "$API_ID" = "None" ]; then
  echo "pinecone-metrics does not exist."
  exit 1
fi
url="$AWS_ENDPOINT_URL/restapis/$API_ID/prod/_user_request_/metrics"
body="$(mktemp)"
trap 'rm -f "$body"' EXIT
status() { curl -s --max-time 60 -o "$body" -w '%{http_code}' "$@" || true; }

route_auth="$(aws_local apigatewayv2 get-routes --api-id "$API_ID" \
  --query "Items[?RouteKey=='GET /metrics'].AuthorizationType | [0]" --output text)"
if [ "$route_auth" != "CUSTOM" ]; then
  echo "GET /metrics is no longer protected by the Lambda authorizer (authorization type: $route_auth). Keep the authorizer on the route."
  exit 1
fi

code="$(status -H 'x-pine-key: pine-7a21' "$url")"
if [ "$code" = "500" ]; then
  echo "A caller with a valid key still gets 500. The authorizer function runs fine; what does API Gateway expect its answer to look like, and how is the authorizer configured to read it?"
  exit 1
fi
if [ "$code" != "200" ] || ! grep -q '"queue_depth"' "$body"; then
  echo "A caller with the valid key got HTTP $code: $(head -c 150 "$body")"
  exit 1
fi
if ! grep -q '"caller": "platform"' "$body"; then
  echo "The metrics function did not see the authorizer's context (caller should be 'platform'): $(head -c 150 "$body")"
  exit 1
fi
code="$(status -H 'x-pine-key: guess' "$url")"
if [ "$code" != "403" ]; then
  echo "A wrong key should be refused with 403, got $code."
  exit 1
fi
code="$(status "$url")"
if [ "$code" != "401" ]; then
  echo "A call without the key should be refused with 401, got $code."
  exit 1
fi
echo "The authorizer's {isAuthorized} answer is understood: valid key 200, wrong key 403, no key 401."
