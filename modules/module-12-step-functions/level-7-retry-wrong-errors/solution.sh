#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("reserve.asl.json"))
retry = doc["States"]["ReserveStock"]["Retry"]
retry.insert(0, {"ErrorEquals": ["StockLocked"], "IntervalSeconds": 2, "MaxAttempts": 4, "BackoffRate": 1.5})
json.dump(doc, open("reserve.asl.json", "w"), indent=2)
PY

aws_local stepfunctions update-state-machine \
  --state-machine-arn "arn:aws:states:us-east-1:${ACCOUNT_ID}:stateMachine:fernhill-reserve" \
  --definition file://reserve.asl.json
