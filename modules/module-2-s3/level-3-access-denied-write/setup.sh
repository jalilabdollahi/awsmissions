#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
aws_local s3 mb s3://mission-bucket >/dev/null 2>&1 || true
printf 'hello
' > /tmp/s3-level3.txt
aws_local s3 cp /tmp/s3-level3.txt s3://mission-bucket/data.txt >/dev/null
aws_local s3api put-bucket-policy   --bucket mission-bucket   --policy '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":"arn:aws:iam::000000000000:root"},"Action":"s3:GetObject","Resource":"arn:aws:s3:::mission-bucket/*"}]}' >/dev/null
echo "Broken bucket created: mission-bucket (write denied by policy)"
