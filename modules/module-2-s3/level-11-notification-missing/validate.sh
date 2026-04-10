#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
cfg="$(aws_local s3api get-bucket-notification-configuration --bucket mission-bucket --output json 2>/dev/null || true)"
if [[ "$cfg" == *'upload-handler'* && "$cfg" == *'s3:ObjectCreated:'* ]]; then
  echo "mission-bucket now has the expected S3-to-Lambda notification."
  exit 0
fi
echo "mission-bucket is still missing the expected notification configuration."
exit 1
