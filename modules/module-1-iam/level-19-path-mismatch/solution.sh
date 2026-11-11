#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<PY
import json
doc = json.load(open("policy.json"))
doc["Statement"][0]["Resource"] = "arn:aws:iam::${ACCOUNT_ID}:user/contractors/\${aws:username}"
json.dump(doc, open("policy.json", "w"), indent=2)
PY

aws_local iam put-group-policy --group-name redwood-contractors --policy-name self-service-keys \
  --policy-document file://policy.json
