#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# Flip the write statement from Deny to Allow in the player's working copy.
python3 - <<'PY'
import json
doc = json.load(open("policy.json"))
for statement in doc["Statement"]:
    if statement.get("Sid") == "WriteUserUploads":
        statement["Effect"] = "Allow"
json.dump(doc, open("policy.json", "w"), indent=2)
PY

aws_local iam put-role-policy --role-name pixelforge-uploader --policy-name uploader-access \
  --policy-document file://policy.json
