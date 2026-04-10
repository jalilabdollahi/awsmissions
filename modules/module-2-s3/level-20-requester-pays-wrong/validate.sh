#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
payer="$(aws_local s3api get-bucket-request-payment --bucket mission-bucket --query Payer --output text 2>/dev/null || true)"
if [[ "$payer" == "BucketOwner" ]]; then
  echo "mission-bucket requester pays is disabled."
  exit 0
fi
echo "mission-bucket still charges the requester."
exit 1
