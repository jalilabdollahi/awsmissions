#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
url="$(aws_local sqs get-queue-url --queue-name mission-queue.fifo --query QueueUrl --output text)"
attrs="$(aws_local sqs get-queue-attributes --queue-url "$url" --attribute-names FifoQueue --query 'Attributes.FifoQueue' --output text)"
[ "$attrs" = "true" ]
echo "success"
