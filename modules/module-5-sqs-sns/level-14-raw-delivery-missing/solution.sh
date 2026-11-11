#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

web_sub="$(aws_local sns list-subscriptions-by-topic \
  --topic-arn "arn:aws:sns:us-east-1:${ACCOUNT_ID}:delta-cart-events" \
  --query "Subscriptions[?Protocol=='sqs'] | [0].SubscriptionArn" --output text)"
echo "enabling raw delivery on $web_sub"
aws_local sns set-subscription-attributes --subscription-arn "$web_sub" \
  --attribute-name RawMessageDelivery --attribute-value true
