#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("order-screening.asl.json"))
doc["States"]["ScoreOrder"]["ResultPath"] = "$.fraud"
json.dump(doc, open("order-screening.asl.json", "w"), indent=2)
PY

aws_local stepfunctions update-state-machine \
  --state-machine-arn "arn:aws:states:us-east-1:${ACCOUNT_ID}:stateMachine:lumen-order-screening" \
  --definition file://order-screening.asl.json
