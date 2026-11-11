#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

sm="arn:aws:states:us-east-1:${ACCOUNT_ID}:stateMachine:marlin-limit-check"

python3 - <<'PY'
import json
doc = json.load(open("limit-check.asl.json"))
doc["States"]["Gate"]["Choices"][0]["NumericGreaterThanEquals"] = 1000
json.dump(doc, open("limit-check.asl.json", "w"), indent=2)
PY

new_version="$(aws_local stepfunctions update-state-machine --state-machine-arn "$sm" \
  --definition file://limit-check.asl.json --publish --version-description "limit back to EUR 1000" \
  --query stateMachineVersionArn --output text)"

aws_local stepfunctions update-state-machine-alias \
  --state-machine-alias-arn "${sm}:live" \
  --routing-configuration "stateMachineVersionArn=${new_version},weight=100"
