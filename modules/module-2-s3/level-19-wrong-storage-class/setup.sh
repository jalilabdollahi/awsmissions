#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
aws_local s3 mb s3://mission-bucket >/dev/null 2>&1 || true
printf 'archive
' > /tmp/s3-level19.txt
aws_local s3api put-object --bucket mission-bucket --key hot-data.txt --body /tmp/s3-level19.txt --storage-class GLACIER >/dev/null
echo "Broken bucket created: mission-bucket (hot-data.txt stored as GLACIER)"
