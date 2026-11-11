#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

topic="$(aws_local sns create-topic --name meridian-oncall --query TopicArn --output text)"
aws_local sqs create-queue --queue-name meridian-oncall-pager >/dev/null
aws_local sns subscribe --topic-arn "$topic" --protocol sqs \
  --notification-endpoint "arn:aws:sqs:us-east-1:${ACCOUNT_ID}:meridian-oncall-pager" >/dev/null

# The metric exists (the service has been publishing it); the alarm does not.
aws_local cloudwatch put-metric-data --namespace Meridian/Checkout --metric-name P99LatencyMs \
  --value 240 --unit Milliseconds

echo "The metric Meridian/Checkout P99LatencyMs has data, but nothing alarms on it."
