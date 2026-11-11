#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# 1. The filter must match the level the API really logs.
aws_local logs put-metric-filter --log-group-name /kp/settlement-api --filter-name settlement-errors \
  --filter-pattern '"level=ERROR"' \
  --metric-transformations metricName=SettlementErrors,metricNamespace=KP/Settlement,metricValue=1

# 2. Alarm on a spike, not on silence, and 3. attach the pager topic.
TOPIC="arn:aws:sns:us-east-1:${ACCOUNT_ID}:kp-oncall-pager"
aws_local cloudwatch put-metric-alarm --alarm-name kp-settlement-errors \
  --namespace KP/Settlement --metric-name SettlementErrors --statistic Sum \
  --period 10 --evaluation-periods 1 --threshold 5 \
  --comparison-operator GreaterThanOrEqualToThreshold --treat-missing-data notBreaching \
  --alarm-actions "$TOPIC"
