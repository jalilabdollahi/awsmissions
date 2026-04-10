#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
cfg="$(aws_local s3api get-bucket-logging --bucket mission-bucket --output json 2>/dev/null || true)"
if [[ "$cfg" == *'logs-bucket'* && "$cfg" == *'mission-bucket/'* ]]; then
  echo "mission-bucket now has server access logging enabled."
  exit 0
fi
echo "mission-bucket still has logging disabled."
exit 1
