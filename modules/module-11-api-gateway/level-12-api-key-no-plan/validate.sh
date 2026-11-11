#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

API_ID="$(aws_local apigateway get-rest-apis --query "items[?name=='trailmix-api'].id | [0]" --output text 2>/dev/null || true)"
if [ -z "$API_ID" ] || [ "$API_ID" = "None" ]; then
  echo "trailmix-api does not exist."
  exit 1
fi
url="$AWS_ENDPOINT_URL/restapis/$API_ID/v1/_user_request_/trails"
body="$(mktemp)"
trap 'rm -f "$body"' EXIT

key_value() {
  aws_local apigateway get-api-keys --include-values \
    --query "items[?name=='$1'].value | [0]" --output text 2>/dev/null || true
}
partner="$(key_value trailmix-partner-key)"
trial="$(key_value trailmix-trial-key)"
if [ -z "$partner" ] || [ "$partner" = "None" ] || [ -z "$trial" ] || [ "$trial" = "None" ]; then
  echo "One of the two API keys was deleted. Keep trailmix-partner-key and trailmix-trial-key; the fix is the usage plan."
  exit 1
fi

code="$(curl -s --max-time 60 -o "$body" -w '%{http_code}' "$url" || true)"
if [ "$code" != "403" ]; then
  echo "A call without an API key got HTTP $code; the method must keep requiring a key."
  exit 1
fi

code="$(curl -s --max-time 60 -o "$body" -w '%{http_code}' -H "x-api-key: $partner" "$url" || true)"
if [ "$code" = "403" ]; then
  echo "The partner key is still refused (403 Forbidden). A key only opens an API when a usage plan links it to a stage of that API."
  exit 1
fi
if [ "$code" != "200" ] || ! grep -q 'Eagle Ridge Loop' "$body"; then
  echo "The partner call returned HTTP $code: $(head -c 150 "$body")"
  exit 1
fi

plan="$(aws_local apigateway get-usage-plans --output json)"
verdict="$(printf '%s' "$plan" | API_ID="$API_ID" python3 -c '
import json, os, sys
api = os.environ["API_ID"]
plans = json.load(sys.stdin)["items"]
mine = [p for p in plans if any(s.get("apiId") == api and s.get("stage") == "v1" for s in p.get("apiStages", []))]
if not mine:
    print("nostage"); sys.exit()
p = mine[0]
t, q = p.get("throttle", {}), p.get("quota", {})
if float(t.get("rateLimit", 0)) != 20 or int(t.get("burstLimit", 0)) != 40:
    print("throttle:%s/%s" % (t.get("rateLimit"), t.get("burstLimit"))); sys.exit()
if int(q.get("limit", 0)) != 10000 or q.get("period") != "DAY":
    print("quota:%s/%s" % (q.get("limit"), q.get("period"))); sys.exit()
print("ok")
')"
case "$verdict" in
  ok) ;;
  nostage) echo "No usage plan is associated with stage v1 of this API."; exit 1 ;;
  throttle:*) echo "The plan's throttle is ${verdict#throttle:} (rate/burst); the contract says 20 and 40."; exit 1 ;;
  quota:*) echo "The plan's quota is ${verdict#quota:} (limit/period); the contract says 10000 per DAY."; exit 1 ;;
esac

# The emulator accepts any key once a plan covers the stage, so membership is checked explicitly:
# real API Gateway would refuse a key that is not in the plan.
plan_id="$(aws_local apigateway get-usage-plans --query "items[?apiStages[?apiId=='$API_ID']].id | [0]" --output text)"
members="$(aws_local apigateway get-usage-plan-keys --usage-plan-id "$plan_id" --query 'items[].name' --output text)"
case " $(printf '%s' "$members" | tr '\t' ' ') " in
  *" trailmix-partner-key "*) ;;
  *) echo "trailmix-partner-key is not a member of the usage plan for this API."; exit 1 ;;
esac
case " $(printf '%s' "$members" | tr '\t' ' ') " in
  *" trailmix-trial-key "*) echo "The trial key is in the plan too. A prospect who has not signed must stay locked out; add only the partner key."; exit 1 ;;
esac
echo "The partner key works under a plan of 20 rps / burst 40 / 10,000 per day; no key and the trial key are refused."
