#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
policy="$(aws_local s3api get-bucket-policy --bucket mission-bucket --query Policy --output text 2>/dev/null || true)"
if [[ "$policy" == *'s3:PutObject'* ]]; then
  echo "mission-bucket policy now allows PutObject."
  exit 0
fi
echo "mission-bucket policy still does not allow PutObject."
exit 1
