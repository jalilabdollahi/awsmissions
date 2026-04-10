#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

aws_local sqs create-queue --queue-name mission-queue >/dev/null 2>&1 || true
aws_local sns create-topic --name mission-topic >/dev/null 2>&1 || true
echo "Broken queue created: queue policy does not allow SNS to send messages"
