#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
cors="$(aws_local s3api get-bucket-cors --bucket mission-bucket --output json 2>/dev/null || true)"
if [[ "$cors" == *'https://myapp.com'* && "$cors" == *'GET'* ]]; then
  echo "mission-bucket now has a CORS rule for https://myapp.com."
  exit 0
fi
echo "mission-bucket still has no usable CORS configuration."
exit 1
