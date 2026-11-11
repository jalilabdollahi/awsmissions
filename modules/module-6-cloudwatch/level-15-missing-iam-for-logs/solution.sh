#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("policy.json"))
actions = doc["Statement"][0]["Action"]
if "logs:PutLogEvents" not in actions:
    actions.append("logs:PutLogEvents")
json.dump(doc, open("policy.json", "w"), indent=2)
PY
aws_local iam put-user-policy --user-name lumen-shipper --policy-name lumen-shipper-logs \
  --policy-document file://policy.json
