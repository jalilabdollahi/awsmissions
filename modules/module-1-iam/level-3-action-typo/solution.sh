#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("policy.json"))
fixes = {"s3:GetObjcet": "s3:GetObject", "s3:PutObjects": "s3:PutObject"}
for st in doc["Statement"]:
    st["Action"] = fixes.get(st["Action"], st["Action"])
json.dump(doc, open("policy.json", "w"), indent=2)
PY

aws_local iam put-user-policy --user-name lantern-thumbs --policy-name thumbnailer \
  --policy-document file://policy.json
