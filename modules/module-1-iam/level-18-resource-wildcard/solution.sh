#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = {
    "Version": "2012-10-17",
    "Statement": [
        {"Sid": "ReadSourceAssets", "Effect": "Allow", "Action": "s3:GetObject",
         "Resource": ["arn:aws:s3:::vantage-assets/*", "arn:aws:s3:::vantage-assets-eu/*"]},
        {"Sid": "WriteFinishedRenders", "Effect": "Allow", "Action": "s3:PutObject",
         "Resource": "arn:aws:s3:::vantage-renders/*"},
    ],
}
json.dump(doc, open("policy.json", "w"), indent=2)
PY

aws_local iam put-user-policy --user-name vantage-render --policy-name render-storage \
  --policy-document file://policy.json
