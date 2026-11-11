#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

topic="$(aws_local sns create-topic --name lighthouse-storm-warnings --query TopicArn --output text)"
aws_local sns subscribe --topic-arn "$topic" --protocol sqs \
  --notification-endpoint "arn:aws:sqs:us-east-1:${ACCOUNT_ID}:harbor-radio-feed"
