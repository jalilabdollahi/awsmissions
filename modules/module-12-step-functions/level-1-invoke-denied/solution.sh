#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("role-policy.json"))
doc["Statement"].append({
    "Sid": "InvokeLabelPrinter",
    "Effect": "Allow",
    "Action": "lambda:InvokeFunction",
    "Resource": "arn:aws:lambda:us-east-1:000000000000:function:print-shipping-label",
})
json.dump(doc, open("role-policy.json", "w"), indent=2)
PY

aws_local iam put-role-policy --role-name tidewater-label-flow-role --policy-name flow-permissions \
  --policy-document file://role-policy.json
