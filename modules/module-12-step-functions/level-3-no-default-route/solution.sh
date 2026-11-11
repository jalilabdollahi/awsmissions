#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("triage.asl.json"))
doc["States"]["ByPriority"]["Default"] = "Backlog"
json.dump(doc, open("triage.asl.json", "w"), indent=2)
PY

aws_local stepfunctions update-state-machine \
  --state-machine-arn "arn:aws:states:us-east-1:${ACCOUNT_ID}:stateMachine:brightwave-ticket-triage" \
  --definition file://triage.asl.json
