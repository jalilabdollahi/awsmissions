#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
cfg="$(aws_local s3api get-public-access-block --bucket mission-bucket --query 'PublicAccessBlockConfiguration' --output json 2>/dev/null || true)"
if [[ "$cfg" == *'"BlockPublicPolicy":false'* ]]; then
  echo "mission-bucket no longer blocks public bucket policies."
  exit 0
fi
echo "mission-bucket still has BlockPublicPolicy enabled."
exit 1
