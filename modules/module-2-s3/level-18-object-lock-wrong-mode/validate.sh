#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
ret="$(aws_local s3api get-object-retention --bucket lock-bucket --key protected.txt --output json 2>/dev/null || true)"
if [[ "$ret" == *'COMPLIANCE'* ]]; then
  echo "protected.txt now uses COMPLIANCE retention mode."
  exit 0
fi
echo "protected.txt is still not in COMPLIANCE mode."
exit 1
