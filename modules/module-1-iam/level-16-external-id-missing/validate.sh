#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

if aws_local sts assume-role --cli-input-json file://config.json >/dev/null 2>&1; then
  echo "AssumeRole succeeds when the correct ExternalId is provided."
  exit 0
fi

echo "AssumeRole still fails. Check config.json and provide the required ExternalId."
exit 1
