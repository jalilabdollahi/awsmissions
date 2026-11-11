#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

if ! url="$(aws_local sqs get-queue-url --queue-name harborline-orders --query QueueUrl --output text 2>/dev/null)"; then
  echo "Queue harborline-orders does not exist yet. The intake service looks it up by exactly that name."
  exit 1
fi

# Behaviour: an order goes in at one end and comes out at the other.
body="order-$(date +%s)-$$"
aws_local sqs send-message --queue-url "$url" --message-body "$body" >/dev/null
got="$(aws_local sqs receive-message --queue-url "$url" --wait-time-seconds 3 --query 'Messages[0].Body' --output text 2>/dev/null || true)"
if [ "$got" != "$body" ]; then
  echo "Sent an order to harborline-orders but the worker side did not receive it back."
  exit 1
fi

wait_s="$(aws_local sqs get-queue-attributes --queue-url "$url" --attribute-names ReceiveMessageWaitTimeSeconds \
  --query 'Attributes.ReceiveMessageWaitTimeSeconds' --output text)"
if [ "$wait_s" != "10" ]; then
  echo "The queue works, but the worker polls all day and ReceiveMessageWaitTimeSeconds is ${wait_s}. Enable long polling with a 10 second wait to stop paying for empty receives."
  exit 1
fi

echo "harborline-orders exists, accepts orders and hands them to the worker with long polling. Warehouse is moving again."
