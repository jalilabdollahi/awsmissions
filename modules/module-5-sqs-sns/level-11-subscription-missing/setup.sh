#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

topic="$(aws_local sns create-topic --name bluebird-checkout-events --query TopicArn --output text)"
aws_local sqs create-queue --queue-name bluebird-fulfilment >/dev/null
aws_local sqs create-queue --queue-name bluebird-loyalty >/dev/null

# Only fulfilment was ever wired up.
aws_local sns subscribe --topic-arn "$topic" --protocol sqs \
  --notification-endpoint "arn:aws:sqs:us-east-1:${ACCOUNT_ID}:bluebird-fulfilment" >/dev/null

echo "bluebird-checkout-events has exactly one subscriber: fulfilment."
