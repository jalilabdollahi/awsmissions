#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

API_ID="$(aws_local apigateway get-rest-apis --query "items[?name=='vaultline-api'].id | [0]" --output text 2>/dev/null || true)"
if [ -z "$API_ID" ] || [ "$API_ID" = "None" ]; then
  echo "vaultline-api does not exist."
  exit 1
fi
url="$AWS_ENDPOINT_URL/restapis/$API_ID/partner/_user_request_/documents"
body="$(mktemp)"
trap 'rm -f "$body"' EXIT
status() { curl -s --max-time 60 -o "$body" -w '%{http_code}' "$@" || true; }

code="$(status -H 'X-Vaultline-Token: vl-partner-7731' "$url")"
if [ "$code" = "401" ]; then
  echo "A partner with a valid X-Vaultline-Token still gets 401 Unauthorized: the authorizer never receives the token because API Gateway looks for it in another place."
  exit 1
fi
if [ "$code" = "403" ]; then
  echo "A valid partner token is now rejected with 403. The authorizer says no: is it getting the right header's value?"
  exit 1
fi
if [ "$code" != "200" ] || ! grep -q 'kyc-bundle-204.zip' "$body"; then
  echo "GET /documents with a valid token returned HTTP $code: $(head -c 150 "$body")"
  exit 1
fi

code="$(status "$url")"
if [ "$code" != "401" ]; then
  echo "A call without any token must be answered 401, but got $code. The method has to stay protected by the authorizer."
  exit 1
fi
code="$(status -H 'X-Vaultline-Token: stolen-token' "$url")"
if [ "$code" != "403" ]; then
  echo "A call with a wrong token must be answered 403 by the authorizer, but got $code."
  exit 1
fi
code="$(status -H 'Authorization: vl-partner-7731' "$url")"
if [ "$code" = "200" ]; then
  echo "The old Authorization header still opens the door as well. The integration guide says X-Vaultline-Token only."
  exit 1
fi
echo "Partners authenticate with X-Vaultline-Token; missing tokens get 401 and wrong tokens 403."
