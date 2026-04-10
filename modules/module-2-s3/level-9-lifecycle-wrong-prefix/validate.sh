#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
cfg="$(aws_local s3api get-bucket-lifecycle-configuration --bucket mission-bucket --output json 2>/dev/null || true)"
if [[ "$cfg" == *'app-logs/'* ]]; then
  echo "mission-bucket lifecycle rule now targets app-logs/."
  exit 0
fi
echo "mission-bucket lifecycle prefix is still wrong."
exit 1
