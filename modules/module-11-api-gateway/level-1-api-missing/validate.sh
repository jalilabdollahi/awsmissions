#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

API_ID="$(aws_local apigateway get-rest-apis --query "items[?name=='lantern-status-api'].id | [0]" --output text 2>/dev/null || true)"
if [ -z "$API_ID" ] || [ "$API_ID" = "None" ]; then
  echo "There is no REST API called lantern-status-api yet."
  exit 1
fi

url="$AWS_ENDPOINT_URL/restapis/$API_ID/live/_user_request_/status"
body="$(mktemp)"
trap 'rm -f "$body"' EXIT
code="$(curl -s --max-time 60 -o "$body" -w '%{http_code}' "$url" || true)"
case "$code" in
  200) ;;
  404) echo "GET /status on stage 'live' returns 404. Either the stage live does not exist, or there is no /status resource wired to something."
       exit 1 ;;
  403) echo "GET /status answered 403 (MissingAuthenticationToken): no GET method exists on a /status resource of this API."
       exit 1 ;;
  *)   echo "GET /status returned HTTP $code: $(head -c 200 "$body")"
       exit 1 ;;
esac

if ! python3 -c '
import json, sys
d = json.load(open(sys.argv[1]))
assert d.get("build") == "2026.11-a7f3" and d.get("state") == "operational", d
' "$body" 2>/dev/null; then
  echo "The endpoint answers 200 but not with the lantern-status function output: $(head -c 200 "$body")"
  echo "The API must hand the request to the function with a Lambda proxy integration, not make up an answer."
  exit 1
fi
echo "GET /status on lantern-status-api (stage live) returns the live status. Status page is back."
