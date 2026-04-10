#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
aws_local s3api create-bucket --bucket lock-bucket --object-lock-enabled-for-bucket >/dev/null 2>&1 || true
printf 'locked
' > /tmp/s3-level18.txt
aws_local s3api put-object --bucket lock-bucket --key protected.txt --body /tmp/s3-level18.txt >/dev/null
aws_local s3api put-object-retention   --bucket lock-bucket   --key protected.txt   --retention Mode=GOVERNANCE,RetainUntilDate=2030-01-01T00:00:00Z   --bypass-governance-retention >/dev/null 2>&1 || true
echo "Broken bucket created: lock-bucket (retention mode is GOVERNANCE)"
