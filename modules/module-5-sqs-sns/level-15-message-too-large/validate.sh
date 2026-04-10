#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
aws_local s3 ls s3://message-payloads >/dev/null
echo "success"
