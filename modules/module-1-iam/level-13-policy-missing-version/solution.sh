#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("policy.json"))
fixed = {"Version": "2012-10-17"}
fixed.update(doc)
json.dump(fixed, open("policy.json", "w"), indent=2)
PY

aws_local iam create-policy-version --policy-arn "arn:aws:iam::${ACCOUNT_ID}:policy/home-folders" \
  --policy-document file://policy.json --set-as-default >/dev/null
