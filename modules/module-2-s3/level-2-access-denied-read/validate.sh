#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
policy="$(aws_local s3api get-bucket-policy --bucket mission-bucket --query Policy --output text 2>/dev/null || true)"
if [[ "$policy" == *'"Effect":"Allow"'* && "$policy" == *'s3:GetObject'* && "$policy" == *'arn:aws:s3:::mission-bucket/*'* ]]; then
  echo "mission-bucket now allows GetObject as expected."
  exit 0
fi
echo "mission-bucket policy still blocks reads."
exit 1
