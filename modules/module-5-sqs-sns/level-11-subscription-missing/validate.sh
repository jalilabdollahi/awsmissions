#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

topic_arn="arn:aws:sns:us-east-1:${ACCOUNT_ID}:bluebird-checkout-events"
fulfil="$(aws_local sqs get-queue-url --queue-name bluebird-fulfilment --query QueueUrl --output text 2>/dev/null || true)"
loyal="$(aws_local sqs get-queue-url --queue-name bluebird-loyalty --query QueueUrl --output text 2>/dev/null || true)"
if [ -z "$fulfil" ] || [ -z "$loyal" ]; then
  echo "Both consumer queues (bluebird-fulfilment, bluebird-loyalty) must exist."
  exit 1
fi

order="checkout-$(date +%s)-$$"
aws_local sns publish --topic-arn "$topic_arn" --message "$order" >/dev/null

has_order() {
  aws_local sqs receive-message --queue-url "$1" --max-number-of-messages 10 --visibility-timeout 0 \
    --query 'Messages[].Body' --output text 2>/dev/null | grep -q "$order"
}
if ! wait_for "fulfilment delivery" 8 has_order "$fulfil"; then
  echo "bluebird-fulfilment stopped receiving checkout events. Leave the existing fulfilment subscription alone."
  exit 1
fi
if ! has_order "$loyal"; then
  # Give an in-flight delivery a moment before giving up.
  if ! wait_for "loyalty delivery" 4 has_order "$loyal"; then
    echo "bluebird-fulfilment got the event, but bluebird-loyalty did not. Which subscriptions does the topic actually have?"
    exit 1
  fi
fi

echo "One checkout event, two queues: fulfilment and loyalty both received it."
