#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

url="$(aws_local sqs create-queue --queue-name tidewater-payments.fifo \
  --attributes FifoQueue=true --query QueueUrl --output text)"

# A capture job that was sent by a worker that does supply its own id.
aws_local sqs send-message --queue-url "$url" --message-group-id merchant-9 \
  --message-deduplication-id cap-000001 \
  --message-body '{"capture":"pay_000001","amount":1250}' >/dev/null

echo "tidewater-payments.fifo rejects callbacks that come without a deduplication id."
