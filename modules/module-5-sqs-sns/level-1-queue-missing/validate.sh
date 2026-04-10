#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
aws_local sqs get-queue-url --queue-name mission-queue >/dev/null
echo "success"
