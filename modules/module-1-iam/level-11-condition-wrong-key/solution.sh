#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("policy.json"))
cond = doc["Statement"][0]["Condition"]["StringEquals"]
doc["Statement"][0]["Condition"]["StringEquals"] = {"aws:RequestedRegion": cond["aws:Region"]}
json.dump(doc, open("policy.json", "w"), indent=2)
PY

aws_local iam put-user-policy --user-name meridian-eu-worker --policy-name eu-sqs-only \
  --policy-document file://policy.json
