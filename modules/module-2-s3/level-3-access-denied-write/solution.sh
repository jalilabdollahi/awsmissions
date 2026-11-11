#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("bucket-policy.json"))
for st in doc["Statement"]:
    if st["Sid"] == "CiPublishesBuilds":
        st["Resource"] = "arn:aws:s3:::nimbus-build-artifacts/artifacts/*"
json.dump(doc, open("bucket-policy.json", "w"), indent=2)
PY

aws_local s3api put-bucket-policy --bucket nimbus-build-artifacts --policy file://bucket-policy.json
