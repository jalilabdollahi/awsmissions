#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("trial-reminder.asl.json"))
wait = doc["States"]["WaitForReminderTime"]
del wait["Seconds"]
wait["TimestampPath"] = "$.remindAt"
json.dump(doc, open("trial-reminder.asl.json", "w"), indent=2)
PY

aws_local stepfunctions update-state-machine \
  --state-machine-arn "arn:aws:states:us-east-1:${ACCOUNT_ID}:stateMachine:halcyon-trial-reminder" \
  --definition file://trial-reminder.asl.json
