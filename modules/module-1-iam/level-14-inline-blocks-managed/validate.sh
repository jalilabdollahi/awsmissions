#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

doc="$(aws_local iam get-role-policy --role-name conflicted-reader-role --policy-name conflicting-policy --query 'PolicyDocument' --output json 2>/dev/null || true)"

if [[ "$doc" != *'"Effect":"Deny"'* && "$doc" == *"s3:GetObject"* && "$doc" == *"arn:aws:s3:::mission-bucket/*"* ]]; then
  echo "The conflicting inline policy no longer blocks access."
  exit 0
fi

echo "The conflicting inline policy still denies S3 access."
exit 1
