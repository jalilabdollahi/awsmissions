#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local s3 mb s3://corvid-access-logs

python3 - <<'PY'
import json
doc = {
    "Version": "2012-10-17",
    "Statement": [{
        "Sid": "AllowS3LogDelivery",
        "Effect": "Allow",
        "Principal": {"Service": "logging.s3.amazonaws.com"},
        "Action": "s3:PutObject",
        "Resource": "arn:aws:s3:::corvid-access-logs/storefront/*",
        "Condition": {"ArnLike": {"aws:SourceArn": "arn:aws:s3:::corvid-storefront-assets"}},
    }],
}
json.dump(doc, open("logging-bucket-policy.json", "w"), indent=2)
PY
aws_local s3api put-bucket-policy --bucket corvid-access-logs --policy file://logging-bucket-policy.json

aws_local s3api put-bucket-logging --bucket corvid-storefront-assets --bucket-logging-status '{
  "LoggingEnabled": {"TargetBucket": "corvid-access-logs", "TargetPrefix": "storefront/"}
}'
