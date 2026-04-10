#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
aws_local s3 mb s3://mission-bucket >/dev/null 2>&1 || true
aws_local s3api put-bucket-lifecycle-configuration   --bucket mission-bucket   --lifecycle-configuration '{"Rules":[{"ID":"expire-logs","Status":"Enabled","Filter":{"Prefix":"logs/"},"Expiration":{"Days":30}}]}' >/dev/null
echo "Broken bucket created: mission-bucket (lifecycle prefix wrong)"
