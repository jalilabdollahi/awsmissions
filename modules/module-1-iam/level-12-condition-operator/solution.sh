#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("policy.json"))
cond = doc["Statement"][0]["Condition"]
cond["StringLike"] = cond.pop("StringEquals")
json.dump(doc, open("policy.json", "w"), indent=2)
PY

aws_local iam put-user-policy --user-name ashgrove-clerk --policy-name clerk-browse \
  --policy-document file://policy.json
