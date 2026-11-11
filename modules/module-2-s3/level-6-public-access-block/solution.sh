#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# Keep the ACL protections; allow public bucket policies.
aws_local s3api put-public-access-block --bucket lumen-brand-assets \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=false,RestrictPublicBuckets=false

# Scope the public statement to the press kit only.
python3 - <<'PY'
import json
doc = json.load(open("public-read-policy.json"))
doc["Statement"][0]["Resource"] = "arn:aws:s3:::lumen-brand-assets/public/*"
json.dump(doc, open("public-read-policy.json", "w"), indent=2)
PY

aws_local s3api put-bucket-policy --bucket lumen-brand-assets --policy file://public-read-policy.json
