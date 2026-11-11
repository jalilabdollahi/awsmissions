#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("boundary.json"))
doc["Statement"].append({
    "Sid": "ReadQuasarParameters",
    "Effect": "Allow",
    "Action": "ssm:GetParameter",
    "Resource": "arn:aws:ssm:us-east-1:000000000000:parameter/quasar/*",
})
json.dump(doc, open("boundary.json", "w"), indent=2)
PY

arn="arn:aws:iam::${ACCOUNT_ID}:policy/quasar-self-service-boundary"
aws_local iam create-policy-version --policy-arn "$arn" --set-as-default \
  --policy-document file://boundary.json >/dev/null
