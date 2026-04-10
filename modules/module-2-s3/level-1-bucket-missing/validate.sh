#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

if aws_local s3api head-bucket --bucket mission-bucket >/dev/null 2>&1; then
  echo "mission-bucket exists."
  exit 0
fi

echo "mission-bucket is still missing."
exit 1
