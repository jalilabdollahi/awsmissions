#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

url="$(aws_local sqs get-queue-url --queue-name tidewater-payments.fifo --query QueueUrl --output text)"
aws_local sqs set-queue-attributes --queue-url "$url" --attributes ContentBasedDeduplication=true
