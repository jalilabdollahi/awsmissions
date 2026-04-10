#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
aws_local s3 mb s3://mission-bucket >/dev/null 2>&1 || true
aws_local s3api put-bucket-acl --bucket mission-bucket --acl public-read >/dev/null
echo "Broken bucket created: mission-bucket (ACL is public-read)"
