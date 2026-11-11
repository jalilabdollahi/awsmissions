#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

topic="$(aws_local sns create-topic --name ember-alerts --query TopicArn --output text)"
aws_local sqs create-queue --queue-name ember-pager-intake >/dev/null
aws_local sns subscribe --topic-arn "$topic" --protocol sqs \
  --notification-endpoint "arn:aws:sqs:us-east-1:${ACCOUNT_ID}:ember-pager-intake" >/dev/null

echo "ember-alerts is subscribed to ember-pager-intake, but the queue has no policy that lets SNS write to it."
