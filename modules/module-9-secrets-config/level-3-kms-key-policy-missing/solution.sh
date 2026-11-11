#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# Add a usage statement for the writer role next to the administrator statement.
python3 - <<'PY'
import json
doc = json.load(open("key-policy.json"))
doc["Statement"].append({
    "Sid": "AllowReportWriterToUseTheKey",
    "Effect": "Allow",
    "Principal": {"AWS": "arn:aws:iam::000000000000:role/orbit-report-writer"},
    "Action": ["kms:Encrypt", "kms:Decrypt", "kms:GenerateDataKey", "kms:DescribeKey"],
    "Resource": "*",
})
json.dump(doc, open("key-policy.json", "w"), indent=2)
PY

key_id="$(aws_local kms describe-key --key-id alias/orbit-reports --query KeyMetadata.KeyId --output text)"
aws_local kms put-key-policy --key-id "$key_id" --policy-name default --policy file://key-policy.json
