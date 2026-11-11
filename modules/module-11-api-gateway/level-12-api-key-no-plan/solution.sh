#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

API_ID="$(aws_local apigateway get-rest-apis --query "items[?name=='trailmix-api'].id | [0]" --output text)"
python3 - "$API_ID" <<'PY'
import json, sys
plan = json.load(open("usage-plan.json"))
plan["apiStages"] = [{"apiId": sys.argv[1], "stage": "v1"}]
plan["throttle"] = {"rateLimit": 20, "burstLimit": 40}
plan["quota"] = {"limit": 10000, "period": "DAY"}
json.dump(plan, open("usage-plan.json", "w"), indent=2)
PY
PLAN_ID="$(aws_local apigateway create-usage-plan --cli-input-json file://usage-plan.json --query id --output text)"
KEY_ID="$(aws_local apigateway get-api-keys --query "items[?name=='trailmix-partner-key'].id | [0]" --output text)"
aws_local apigateway create-usage-plan-key --usage-plan-id "$PLAN_ID" --key-id "$KEY_ID" --key-type API_KEY >/dev/null
