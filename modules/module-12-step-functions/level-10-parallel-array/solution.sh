#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("profile-card.asl.json"))
states = doc["States"]
states["Gather"]["ResultSelector"] = {"billing.$": "$[0]", "usage.$": "$[1]"}
states["Gather"]["ResultPath"] = "$.lookups"
body = states["PublishCard"]["Parameters"]["MessageBody"]
body["plan.$"] = "$.lookups.billing.plan"
body["gbUsed.$"] = "$.lookups.usage.gbUsed"
json.dump(doc, open("profile-card.asl.json", "w"), indent=2)
PY

aws_local stepfunctions update-state-machine \
  --state-machine-arn "arn:aws:states:us-east-1:${ACCOUNT_ID}:stateMachine:orbit-profile-card" \
  --definition file://profile-card.asl.json
