#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
cfg="$(aws_local s3api get-bucket-notification-configuration --bucket mission-bucket --output json 2>/dev/null || true)"
if [[ "$cfg" == *'s3:ObjectCreated:'* && "$cfg" != *'s3:ObjectRemoved:'* ]]; then
  echo "mission-bucket now uses the correct notification event."
  exit 0
fi
echo "mission-bucket still uses the wrong notification event."
exit 1
