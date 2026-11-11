#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("policy.json"))
doc["Statement"].append({
    "Sid": "ReadReportObjects",
    "Effect": "Allow",
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::harborline-reports/reports/*",
})
json.dump(doc, open("policy.json", "w"), indent=2)
PY

aws_local iam put-user-policy --user-name ledgerlens-report --policy-name report-access \
  --policy-document file://policy.json
