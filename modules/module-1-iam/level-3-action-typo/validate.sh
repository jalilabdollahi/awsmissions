#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

action="$(aws_local iam get-role-policy \
  --role-name object-reader-role \
  --policy-name object-reader-policy \
  --query 'PolicyDocument.Statement[0].Action' \
  --output text 2>/dev/null || true)"

resource="$(aws_local iam get-role-policy \
  --role-name object-reader-role \
  --policy-name object-reader-policy \
  --query 'PolicyDocument.Statement[0].Resource' \
  --output text 2>/dev/null || true)"

effect="$(aws_local iam get-role-policy \
  --role-name object-reader-role \
  --policy-name object-reader-policy \
  --query 'PolicyDocument.Statement[0].Effect' \
  --output text 2>/dev/null || true)"

if [[ "$effect" == "Allow" && "$action" == *"s3:GetObject"* && "$resource" == *"arn:aws:s3:::mission-bucket/*"* ]]; then
  echo "object-reader-policy correctly allows s3:GetObject on mission-bucket/*."
  exit 0
fi

echo "object-reader-policy still has the wrong action or resource."
exit 1
