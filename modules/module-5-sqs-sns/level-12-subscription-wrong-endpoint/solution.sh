#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

topic_arn="arn:aws:sns:us-east-1:${ACCOUNT_ID}:quartz-invoice-events"
old_sub="$(aws_local sns list-subscriptions-by-topic --topic-arn "$topic_arn" \
  --query "Subscriptions[?Endpoint=='arn:aws:sqs:us-east-1:${ACCOUNT_ID}:quartz-invoices-staging'].SubscriptionArn | [0]" \
  --output text)"
aws_local sns unsubscribe --subscription-arn "$old_sub"
aws_local sns subscribe --topic-arn "$topic_arn" --protocol sqs \
  --notification-endpoint "arn:aws:sqs:us-east-1:${ACCOUNT_ID}:quartz-invoices-prod"
