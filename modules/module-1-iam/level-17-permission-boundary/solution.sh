#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("boundary.json"))
doc["Statement"][0]["Action"].append("s3:PutObject")
json.dump(doc, open("boundary.json", "w"), indent=2)
PY

aws_local iam create-policy-version --policy-arn "arn:aws:iam::${ACCOUNT_ID}:policy/intern-boundary" \
  --policy-document file://boundary.json --set-as-default >/dev/null
