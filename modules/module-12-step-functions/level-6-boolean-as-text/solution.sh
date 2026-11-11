#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("dispatch.asl.json"))
doc["States"]["PickLane"]["Choices"] = [{
    "And": [
        {"Variable": "$.express", "IsPresent": True},
        {"Variable": "$.express", "BooleanEquals": True},
    ],
    "Next": "ExpressLane",
}]
json.dump(doc, open("dispatch.asl.json", "w"), indent=2)
PY

aws_local stepfunctions update-state-machine \
  --state-machine-arn "arn:aws:states:us-east-1:${ACCOUNT_ID}:stateMachine:quillon-dispatch" \
  --definition file://dispatch.asl.json
