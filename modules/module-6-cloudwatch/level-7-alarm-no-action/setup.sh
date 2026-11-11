#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

oncall="$(aws_local sns create-topic --name halcyon-oncall --query TopicArn --output text)"
aws_local sns create-topic --name halcyon-oncall-legacy >/dev/null
aws_local sqs create-queue --queue-name halcyon-pager-app >/dev/null
aws_local sns subscribe --topic-arn "$oncall" --protocol sqs \
  --notification-endpoint "arn:aws:sqs:us-east-1:${ACCOUNT_ID}:halcyon-pager-app" >/dev/null

aws_local cloudwatch put-metric-alarm --cli-input-json "file://$MISSION_DIR/workspace/alarm.json"

echo "halcyon-db-connections-high is defined; its actions are muted and aimed at the legacy topic."
