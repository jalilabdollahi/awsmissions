#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("policy.json"))
st = doc["Statement"][0]
st["Action"] = ["sqs:SendMessage", "sqs:GetQueueUrl"]
st["Resource"] = "arn:aws:sqs:us-east-1:000000000000:gatehouse-intake"
json.dump(doc, open("policy.json", "w"), indent=2)
PY

aws_local iam put-user-policy --user-name gatehouse-api --policy-name intake-writer \
  --policy-document file://policy.json
