#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
url="$(aws_local sqs get-queue-url --queue-name mission-queue.fifo --query QueueUrl --output text)"
value="$(aws_local sqs get-queue-attributes --queue-url "$url" --attribute-names ContentBasedDeduplication --query 'Attributes.ContentBasedDeduplication' --output text)"
[ "$value" = "true" ]
echo "success"
