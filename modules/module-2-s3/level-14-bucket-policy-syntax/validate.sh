#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
policy="$(aws_local s3api get-bucket-policy --bucket mission-bucket --query Policy --output text 2>/dev/null || true)"
if [[ "$policy" == *'s3:GetObject'* && "$policy" == *'arn:aws:s3:::mission-bucket/*'* ]]; then
  echo "mission-bucket now has a valid readable bucket policy."
  exit 0
fi
echo "mission-bucket still does not have a valid bucket policy attached."
exit 1
