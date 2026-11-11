#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("refill-flow.asl.json"))
doc["States"]["CheckEligibility"]["Resource"] = (
    "arn:aws:lambda:us-east-1:000000000000:function:refill-eligibility-check")
json.dump(doc, open("refill-flow.asl.json", "w"), indent=2)
PY

aws_local stepfunctions update-state-machine \
  --state-machine-arn "arn:aws:states:us-east-1:${ACCOUNT_ID}:stateMachine:harborview-refill-flow" \
  --definition file://refill-flow.asl.json
