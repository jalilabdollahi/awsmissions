#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

API_ID="$(aws_local apigateway get-rest-apis --query "items[?name=='invoicely-portal'].id | [0]" --output text 2>/dev/null || true)"
if [ -z "$API_ID" ] || [ "$API_ID" = "None" ]; then
  echo "invoicely-portal does not exist."
  exit 1
fi
out="$(mktemp)"
trap 'rm -f "$out"' EXIT
code="$(curl -s --max-time 60 -o "$out" -w '%{http_code}' \
  "$AWS_ENDPOINT_URL/restapis/$API_ID/prod/_user_request_/invoices/latest" || true)"
if [ "$code" != "200" ]; then
  echo "GET /invoices/latest returned HTTP $code: $(head -c 200 "$out")"
  echo "Read the message: it tells you which target API Gateway tried to call."
  exit 1
fi
if grep -q '"environment": "staging"' "$out"; then
  echo "The portal now serves invoices from the STAGING sandbox. Customers must be wired to the production function."
  exit 1
fi
if ! grep -q '"environment": "production"' "$out"; then
  echo "Unexpected answer from the endpoint: $(head -c 200 "$out")"
  exit 1
fi
echo "The portal receives production invoices again."
