#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
cls="$(aws_local s3api head-object --bucket mission-bucket --key hot-data.txt --query StorageClass --output text 2>/dev/null || true)"
if [[ "$cls" == "STANDARD" || "$cls" == "None" ]]; then
  echo "hot-data.txt now uses the STANDARD storage class."
  exit 0
fi
echo "hot-data.txt is still stored with the wrong storage class."
exit 1
