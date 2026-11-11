#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

API_ID="$(aws_local apigateway get-rest-apis --query "items[?name=='cobaltpay-rates'].id | [0]" --output text 2>/dev/null || true)"
if [ -z "$API_ID" ] || [ "$API_ID" = "None" ]; then
  echo "The API cobaltpay-rates is gone; it has to stay."
  exit 1
fi

code="$(curl -s --max-time 60 -o /dev/null -w '%{http_code}' "$AWS_ENDPOINT_URL/restapis/$API_ID/live/_user_request_/rates" || true)"
if [ "$code" != "200" ]; then
  echo "GET /rates on stage live returned $code; it must keep working while you fix the policy."
  exit 1
fi

policy="$(aws_local lambda get-policy --function-name cobaltpay-fx-rates --query Policy --output text 2>/dev/null || true)"
if [ -z "$policy" ] || [ "$policy" = "None" ]; then
  echo "cobaltpay-fx-rates has no resource-based policy at all, so API Gateway has no permission to invoke it."
  exit 1
fi

verdict="$(printf '%s' "$policy" | API_ID="$API_ID" python3 -c '
import json, os, sys
api = os.environ["API_ID"]
doc = json.load(sys.stdin)
good = False
for st in doc.get("Statement", []):
    principal = st.get("Principal", {})
    svc = principal.get("Service") if isinstance(principal, dict) else principal
    cond = json.dumps(st.get("Condition", {}))
    if svc == "*" or principal == "*":
        print("openprincipal"); sys.exit()
    if svc != "apigateway.amazonaws.com":
        continue
    if "execute-api" not in cond:
        print("nosource"); sys.exit()
    if api not in cond:
        print("stale"); sys.exit()
    if "/*/*/*" in cond or (":*:*" in cond and api not in cond):
        print("wide"); sys.exit()
    if "GET/rates" in cond or "/GET/rates" in cond:
        good = True
    else:
        print("scope"); sys.exit()
print("ok" if good else "missing")
')"
case "$verdict" in
  ok) echo "Only the current cobaltpay-rates API (GET /rates) may invoke the function; the stale grant is gone." ;;
  missing) echo "No statement lets apigateway.amazonaws.com invoke the function for the current API ($API_ID)."; exit 1 ;;
  stale) echo "A statement still refers to a different (deleted) API id. Remove leftovers; they are dormant access."; exit 1 ;;
  nosource) echo "A statement for apigateway.amazonaws.com has no source ARN condition: any API in any account could call the function."; exit 1 ;;
  wide) echo "The source ARN is a wildcard over all stages, methods and paths. Limit it to GET /rates of this API."; exit 1 ;;
  scope) echo "The source ARN does not match GET /rates of this API."; exit 1 ;;
  openprincipal) echo "The policy allows every principal to invoke the function. That is far too open."; exit 1 ;;
esac
