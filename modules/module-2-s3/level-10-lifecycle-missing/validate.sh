#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
cfg="$(aws_local s3api get-bucket-lifecycle-configuration --bucket mission-bucket --output json 2>/dev/null || true)"
if [[ "$cfg" == *'DaysAfterInitiation'* && "$cfg" == *'7'* ]]; then
  echo "mission-bucket now aborts incomplete multipart uploads after 7 days."
  exit 0
fi
echo "mission-bucket still has no abort-incomplete-multipart-upload rule."
exit 1
