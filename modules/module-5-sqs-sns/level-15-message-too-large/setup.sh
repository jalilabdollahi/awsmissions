#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

aws_local s3 mb s3://message-payloads >/dev/null 2>&1 || true
aws_local sqs create-queue --queue-name mission-queue >/dev/null 2>&1 || true
echo "Broken state prepared: application needs S3 offload for payloads larger than 256KB"
