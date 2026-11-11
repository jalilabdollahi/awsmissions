#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("signup.asl.json"))
item = doc["States"]["SaveSubscriber"]["Parameters"]["Item"]
item["email"] = {"S.$": "$.email"}
item["welcomeLine"] = {"S.$": item["welcomeLine"]["S"]}
json.dump(doc, open("signup.asl.json", "w"), indent=2)
PY

aws_local stepfunctions update-state-machine \
  --state-machine-arn "arn:aws:states:us-east-1:${ACCOUNT_ID}:stateMachine:saffron-signup" \
  --definition file://signup.asl.json
