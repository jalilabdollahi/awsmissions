#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
aws_local sqs get-queue-url --queue-name mission-queue --query QueueUrl --output text >/dev/null
echo "success"
