#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local s3 mb s3://pixelforge-uploads >/dev/null
aws_local s3 mb s3://pixelforge-billing-exports >/dev/null

# The worker authenticates as this user and assumes the role.
aws_local iam create-user --user-name upload-worker >/dev/null
aws_local iam put-user-policy --user-name upload-worker --policy-name assume-uploader \
  --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Resource\":\"arn:aws:iam::${ACCOUNT_ID}:role/pixelforge-uploader\"}]}"

aws_local iam create-role --role-name pixelforge-uploader \
  --assume-role-policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::${ACCOUNT_ID}:user/upload-worker\"},\"Action\":\"sts:AssumeRole\"}]}" >/dev/null

# The "cleanup" flipped the write statement to Deny.
aws_local iam put-role-policy --role-name pixelforge-uploader --policy-name uploader-access \
  --policy-document "file://$MISSION_DIR/workspace/policy.json"

echo "pixelforge-uploader is live — and every upload is being rejected."
