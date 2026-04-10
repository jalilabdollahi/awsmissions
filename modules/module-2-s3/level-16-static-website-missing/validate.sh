#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
cfg="$(aws_local s3api get-bucket-website --bucket mission-bucket --output json 2>/dev/null || true)"
if [[ "$cfg" == *'index.html'* && "$cfg" == *'error.html'* ]]; then
  echo "mission-bucket now has static website hosting enabled."
  exit 0
fi
echo "mission-bucket still has website hosting disabled."
exit 1
