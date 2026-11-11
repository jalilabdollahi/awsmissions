#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<PY
import json
doc = json.load(open("trust-policy.json"))
doc["Statement"][0]["Principal"]["AWS"] = "arn:aws:iam::${ACCOUNT_ID}:user/ledger-batch"
json.dump(doc, open("trust-policy.json", "w"), indent=2)
PY

aws_local iam update-assume-role-policy --role-name ledger-nightly \
  --policy-document file://trust-policy.json
