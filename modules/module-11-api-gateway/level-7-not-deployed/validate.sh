#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

API_ID="$(aws_local apigateway get-rest-apis --query "items[?name=='skyhook-weather'].id | [0]" --output text 2>/dev/null || true)"
if [ -z "$API_ID" ] || [ "$API_ID" = "None" ]; then
  echo "skyhook-weather is gone."
  exit 1
fi
out="$(mktemp)"
trap 'rm -f "$out"' EXIT

call() {
  curl -s --max-time 60 -o "$out" -w '%{http_code}' "$AWS_ENDPOINT_URL/restapis/$API_ID/$1/_user_request_/conditions" || true
}

code="$(call prod)"
if [ "$code" = "404" ]; then
  echo "GET /conditions on stage prod: 404 Not Found. A stage called prod does not exist yet (aws apigateway get-stages shows what does)."
  exit 1
fi
if [ "$code" != "200" ]; then
  echo "GET /conditions on prod returned HTTP $code: $(head -c 160 "$out")"
  exit 1
fi
if grep -q '"answered_by": "unknown"' "$out"; then
  echo "prod answers, but the stage variable tier is not set there, so the function reports 'unknown'."
  exit 1
fi
if ! grep -q '"answered_by": "production"' "$out"; then
  echo "prod reports a wrong environment: $(head -c 160 "$out"). The stage variable tier must be exactly 'production'."
  exit 1
fi

code="$(call dev)"
if [ "$code" != "200" ] || ! grep -q '"answered_by": "development"' "$out"; then
  echo "The dev stage must stay untouched (answering development). Got HTTP $code: $(head -c 120 "$out")"
  exit 1
fi
echo "prod is live and says production; dev still says development."
