#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
cors="$(aws_local s3api get-bucket-cors --bucket mission-bucket --output json 2>/dev/null || true)"
if [[ "$cors" == *'https://myapp.com'* && "$cors" != *'https://wrong-app.com'* ]]; then
  echo "mission-bucket now allows the correct CORS origin."
  exit 0
fi
echo "mission-bucket still allows the wrong CORS origin."
exit 1
