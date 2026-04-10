#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

effect="$(aws_local iam get-role-policy \
  --role-name uploader-role \
  --policy-name uploader-policy \
  --query 'PolicyDocument.Statement[0].Effect' \
  --output text 2>/dev/null || true)"

action="$(aws_local iam get-role-policy \
  --role-name uploader-role \
  --policy-name uploader-policy \
  --query 'PolicyDocument.Statement[0].Action' \
  --output text 2>/dev/null || true)"

resource="$(aws_local iam get-role-policy \
  --role-name uploader-role \
  --policy-name uploader-policy \
  --query 'PolicyDocument.Statement[0].Resource' \
  --output text 2>/dev/null || true)"

if [[ "$effect" == "Allow" && "$action" == *"s3:PutObject"* && "$resource" == *"arn:aws:s3:::uploads-bucket/*"* ]]; then
  echo "uploader-policy correctly allows writes to uploads-bucket."
  exit 0
fi

echo "uploader-policy still does not allow s3:PutObject on uploads-bucket/*"
exit 1
