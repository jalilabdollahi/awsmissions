#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
B=pixelcart-feature-flags

aws_local s3 mb "s3://$B" >/dev/null
aws_local s3api put-bucket-versioning --bucket "$B" --versioning-configuration Status=Enabled

echo '{"new_checkout": false}' > "$work/v1.json"
echo '{"new_checkout": true, "rollout": 50}' > "$work/v2.json"
echo '{"new_checkout": ERR, "rollout": }' > "$work/bad.json"

aws_local s3api put-object --bucket "$B" --key flags.json --body "$work/v1.json" >/dev/null
sleep 1  # distinct LastModified timestamps, like real publishes
aws_local s3api put-object --bucket "$B" --key flags.json --body "$work/v2.json" >/dev/null

# The "cost saving" pause, followed by the botched deploy.
aws_local s3api put-bucket-versioning --bucket "$B" --versioning-configuration Status=Suspended
aws_local s3api put-object --bucket "$B" --key flags.json --body "$work/bad.json" >/dev/null

aws_local iam create-user --user-name flag-publisher >/dev/null
aws_local iam put-user-policy --user-name flag-publisher --policy-name flags-rw \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {"Effect": "Allow", "Action": ["s3:ListBucket", "s3:ListBucketVersions"], "Resource": "arn:aws:s3:::pixelcart-feature-flags"},
      {"Effect": "Allow", "Action": ["s3:GetObject", "s3:GetObjectVersion", "s3:PutObject"], "Resource": "arn:aws:s3:::pixelcart-feature-flags/*"}
    ]
  }'

echo "flags.json is corrupted and the bucket has stopped versioning."
