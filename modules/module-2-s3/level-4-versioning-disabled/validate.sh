#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
status="$(aws_local s3api get-bucket-versioning --bucket mission-bucket --query Status --output text 2>/dev/null || true)"
if [[ "$status" == "Enabled" ]]; then
  echo "mission-bucket versioning is enabled."
  exit 0
fi
echo "mission-bucket versioning is still disabled."
exit 1
