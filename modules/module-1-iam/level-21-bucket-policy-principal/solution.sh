#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<PY
import json
doc = {
    "Version": "2012-10-17",
    "Statement": [
        {"Sid": "PartnerReviewerList", "Effect": "Allow",
         "Principal": {"AWS": "arn:aws:iam::${ACCOUNT_ID}:user/proofreader"},
         "Action": "s3:ListBucket", "Resource": "arn:aws:s3:::harborprint-proofs"},
        {"Sid": "PartnerReviewerRead", "Effect": "Allow",
         "Principal": {"AWS": "arn:aws:iam::${ACCOUNT_ID}:user/proofreader"},
         "Action": "s3:GetObject", "Resource": "arn:aws:s3:::harborprint-proofs/proofs/*"},
    ],
}
json.dump(doc, open("bucket-policy.json", "w"), indent=2)
PY

aws_local s3api put-bucket-policy --bucket harborprint-proofs --policy file://bucket-policy.json
