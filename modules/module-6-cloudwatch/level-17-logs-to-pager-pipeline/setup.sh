#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

topic="$(aws_local sns create-topic --name talon-oncall --query TopicArn --output text)"
aws_local sqs create-queue --queue-name talon-pager >/dev/null
aws_local sns subscribe --topic-arn "$topic" --protocol sqs \
  --notification-endpoint "arn:aws:sqs:us-east-1:${ACCOUNT_ID}:talon-pager" >/dev/null

aws_local logs create-log-group --log-group-name /talon/orders-api
aws_local logs create-log-stream --log-group-name /talon/orders-api --log-stream-name api-1
aws_local logs put-metric-filter --cli-input-json "file://$MISSION_DIR/workspace/filter.json"
aws_local cloudwatch put-metric-alarm --cli-input-json "file://$MISSION_DIR/workspace/alarm.json"

echo "Filter, alarm and topic exist. The chain has never produced a page."
