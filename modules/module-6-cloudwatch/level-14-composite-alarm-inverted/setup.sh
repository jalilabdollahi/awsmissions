#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

topic="$(aws_local sns create-topic --name strata-oncall --query TopicArn --output text)"
aws_local sqs create-queue --queue-name strata-oncall-pager >/dev/null
aws_local sns subscribe --topic-arn "$topic" --protocol sqs \
  --notification-endpoint "arn:aws:sqs:us-east-1:${ACCOUNT_ID}:strata-oncall-pager" >/dev/null

aws_local cloudwatch put-metric-alarm --alarm-name strata-api-errors \
  --namespace Strata/Api --metric-name Http5xx --statistic Maximum --period 10 \
  --evaluation-periods 1 --threshold 25 --comparison-operator GreaterThanThreshold \
  --treat-missing-data notBreaching
aws_local cloudwatch put-metric-alarm --alarm-name strata-api-latency \
  --namespace Strata/Api --metric-name LatencyMs --statistic Maximum --period 10 \
  --evaluation-periods 1 --threshold 500 --comparison-operator GreaterThanThreshold \
  --treat-missing-data notBreaching

aws_local cloudwatch put-composite-alarm --alarm-name strata-api-unhealthy \
  --alarm-rule "$(cat "$MISSION_DIR/workspace/alarm-rule.txt")" \
  --alarm-actions "$topic"

echo "strata-api-unhealthy is deployed. It will page as soon as it has evaluated the quiet children."
