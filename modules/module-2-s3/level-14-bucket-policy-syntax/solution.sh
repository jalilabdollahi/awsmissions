#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("bucket-policy.json"))
for st in doc["Statement"]:
    if st["Sid"] == "PartnerListsDropFolders":
        st["Condition"] = {"StringLike": {"s3:prefix": ["outbound/*", "inbound/*"]}}
    elif st["Sid"] == "PartnerDownloadsOutbound":
        st["Action"] = "s3:GetObject"
    elif st["Sid"] == "PartnerUploadsInbound":
        st["Principal"] = {"AWS": "arn:aws:iam::000000000000:user/partner-sync"}
json.dump(doc, open("bucket-policy.json", "w"), indent=2)
PY

aws_local s3api put-bucket-policy --bucket quillhouse-partner-drop --policy file://bucket-policy.json
