#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
cfg="$(aws_local s3api get-bucket-encryption --bucket mission-bucket --output json 2>/dev/null || true)"
if [[ "$cfg" == *'AES256'* ]]; then
  echo "mission-bucket now has default SSE-S3 encryption."
  exit 0
fi
echo "mission-bucket still has no default SSE-S3 encryption."
exit 1
