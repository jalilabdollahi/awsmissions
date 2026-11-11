#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("task-role-policy.json"))
doc["Statement"] = [
    {"Sid": "ListUploads", "Effect": "Allow", "Action": "s3:ListBucket", "Resource": "arn:aws:s3:::pixelmill-uploads"},
    {"Sid": "ReadUploads", "Effect": "Allow", "Action": "s3:GetObject", "Resource": "arn:aws:s3:::pixelmill-uploads/*"},
    {"Sid": "WriteThumbs", "Effect": "Allow", "Action": "s3:PutObject", "Resource": "arn:aws:s3:::pixelmill-thumbs/*"},
]
json.dump(doc, open("task-role-policy.json", "w"), indent=2)
PY
aws_local iam put-role-policy --role-name pixelmill-task-role --policy-name resizer-s3 --policy-document file://task-role-policy.json
