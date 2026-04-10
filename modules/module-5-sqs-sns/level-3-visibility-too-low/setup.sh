#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

aws_local sqs create-queue --queue-name mission-queue --attributes VisibilityTimeout=5 >/dev/null 2>&1 || true
echo "Broken queue created: visibility timeout is 5 seconds"
