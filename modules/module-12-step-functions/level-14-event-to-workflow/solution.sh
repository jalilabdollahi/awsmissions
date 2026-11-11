#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json

pattern = json.load(open("order-placed-pattern.json"))
pattern["detail-type"] = ["OrderPlaced"]
json.dump(pattern, open("order-placed-pattern.json", "w"), indent=2)

targets = json.load(open("rule-targets.json"))
targets[0]["Arn"] = "arn:aws:states:us-east-1:000000000000:stateMachine:cedarpoint-fulfilment"
targets[0]["InputPath"] = "$.detail"
json.dump(targets, open("rule-targets.json", "w"), indent=2)

policy = json.load(open("workflow-role-policy.json"))
for stmt in policy["Statement"]:
    if stmt["Sid"] == "AllocateStock":
        stmt["Resource"] = "arn:aws:lambda:us-east-1:000000000000:function:cedarpoint-allocate-stock"
json.dump(policy, open("workflow-role-policy.json", "w"), indent=2)
PY

aws_local events put-rule --name cedarpoint-order-placed --event-pattern file://order-placed-pattern.json
aws_local events put-targets --rule cedarpoint-order-placed --targets file://rule-targets.json
aws_local iam put-role-policy --role-name cedarpoint-fulfilment-role --policy-name fulfilment \
  --policy-document file://workflow-role-policy.json
