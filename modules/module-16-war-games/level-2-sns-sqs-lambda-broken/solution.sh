#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

TOPIC="arn:aws:sns:us-east-1:${ACCOUNT_ID}:tt-ticket-events"
QARN="arn:aws:sqs:us-east-1:${ACCOUNT_ID}:tt-ticket-fulfilment"

# 1. Fix the subscription: new event name, raw delivery.
SUB="$(aws_local sns list-subscriptions-by-topic --topic-arn "$TOPIC" --query 'Subscriptions[0].SubscriptionArn' --output text)"
aws_local sns set-subscription-attributes --subscription-arn "$SUB" --attribute-name FilterPolicy \
  --attribute-value '{"eventType":["TicketSold"]}'
aws_local sns set-subscription-attributes --subscription-arn "$SUB" --attribute-name RawMessageDelivery \
  --attribute-value true

# 2. Turn the event source mapping back on.
UUID="$(aws_local lambda list-event-source-mappings --function-name tt-ticket-fulfiller --query 'EventSourceMappings[0].UUID' --output text)"
aws_local lambda update-event-source-mapping --uuid "$UUID" --enabled >/dev/null

# 3. Lift the zero concurrency cap.
aws_local lambda delete-function-concurrency --function-name tt-ticket-fulfiller
