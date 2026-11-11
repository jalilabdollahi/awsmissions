#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("policy.json"))
statement = doc["Statement"][0]
statement["Sid"] = "PublishScans"
statement["Action"] = ["kinesis:PutRecord", "kinesis:PutRecords"]
statement["Resource"] = "arn:aws:kinesis:us-east-1:000000000000:stream/parcel-scans"
json.dump(doc, open("policy.json", "w"), indent=2)
PY

aws_local iam put-user-policy --user-name scan-gateway --policy-name depot-publish \
  --policy-document file://policy.json
