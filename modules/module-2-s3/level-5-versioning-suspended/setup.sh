#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
aws_local s3 mb s3://mission-bucket >/dev/null 2>&1 || true
aws_local s3api put-bucket-versioning --bucket mission-bucket --versioning-configuration Status=Enabled >/dev/null
aws_local s3api put-bucket-versioning --bucket mission-bucket --versioning-configuration Status=Suspended >/dev/null
echo "Broken bucket created: mission-bucket (versioning suspended)"
