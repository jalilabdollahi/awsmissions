#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

topic="$(aws_local sns create-topic --name delta-cart-events --query TopicArn --output text)"
aws_local sqs create-queue --queue-name delta-web-analytics >/dev/null
aws_local sns subscribe --topic-arn "$topic" --protocol sqs \
  --notification-endpoint "arn:aws:sqs:us-east-1:${ACCOUNT_ID}:delta-web-analytics" \
  --attributes '{"FilterPolicy":"{\"channel\":[\"web\"]}"}' >/dev/null

echo "delta-web-analytics receives web events wrapped in the SNS notification envelope."
