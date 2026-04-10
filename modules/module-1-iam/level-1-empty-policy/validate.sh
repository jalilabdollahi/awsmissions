#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

doc="$(aws_local iam get-role-policy \
  --role-name report-reader-role \
  --policy-name report-reader-policy \
  --query 'PolicyDocument' \
  --output json)"

if [[ "$doc" == *"s3:GetObject"* && "$doc" == *"arn:aws:s3:::mission-bucket/*"* ]]; then
  echo "Policy now grants s3:GetObject to the correct bucket."
  exit 0
fi

echo "report-reader-policy still does not allow s3:GetObject on mission-bucket/*"
exit 1
