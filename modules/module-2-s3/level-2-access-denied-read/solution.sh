#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("bucket-policy.json"))
st = doc["Statement"][0]
st["Principal"]["AWS"] = "arn:aws:iam::000000000000:user/auditor-dana"
st["Resource"] = "arn:aws:s3:::meridian-audit-reports/reports/*"
json.dump(doc, open("bucket-policy.json", "w"), indent=2)
PY

aws_local s3api put-bucket-policy --bucket meridian-audit-reports --policy file://bucket-policy.json
