#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source ../../../scripts/aws_helpers.sh
aws_local s3 mb s3://mission-bucket >/dev/null 2>&1 || true
printf 'secret
' > /tmp/s3-level2.txt
aws_local s3 cp /tmp/s3-level2.txt s3://mission-bucket/data.txt >/dev/null
aws_local s3api put-bucket-policy   --bucket mission-bucket   --policy '{"Version":"2012-10-17","Statement":[{"Effect":"Deny","Principal":"*","Action":"s3:GetObject","Resource":"arn:aws:s3:::mission-bucket/*"}]}' >/dev/null
echo "Broken bucket created: mission-bucket (GetObject denied by bucket policy)"
