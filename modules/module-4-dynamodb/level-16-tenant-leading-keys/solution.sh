#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("portal-policy.json"))
st = doc["Statement"][0]
st["Action"] = [a for a in st["Action"] if a != "dynamodb:Scan"]
st["Condition"] = {"ForAllValues:StringEquals": {"dynamodb:LeadingKeys": ["acme"]}}
json.dump(doc, open("portal-policy.json", "w"), indent=2)
PY
aws_local iam put-user-policy --user-name portal-acme --policy-name portal-data-access \
  --policy-document file://portal-policy.json
