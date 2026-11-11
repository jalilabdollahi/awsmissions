#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local logs create-log-group --log-group-name /kp/settlement-api >/dev/null
aws_local logs create-log-stream --log-group-name /kp/settlement-api --log-stream-name api-7f3c >/dev/null

aws_local sqs create-queue --queue-name kp-pager-inbox >/dev/null
TOPIC="$(aws_local sns create-topic --name kp-oncall-pager --query TopicArn --output text)"
aws_local sns subscribe --topic-arn "$TOPIC" --protocol sqs \
  --notification-endpoint "arn:aws:sqs:us-east-1:${ACCOUNT_ID}:kp-pager-inbox" >/dev/null

# Someone copied the filter from a different service that logs at FATAL.
aws_local logs put-metric-filter --log-group-name /kp/settlement-api --filter-name settlement-errors \
  --filter-pattern '"level=FATAL"' \
  --metric-transformations metricName=SettlementErrors,metricNamespace=KP/Settlement,metricValue=1

# The alarm exists, but it was cloned from a "healthy traffic" alarm and never wired to the topic.
aws_local cloudwatch put-metric-alarm --alarm-name kp-settlement-errors \
  --namespace KP/Settlement --metric-name SettlementErrors --statistic Sum \
  --period 10 --evaluation-periods 1 --threshold 5 \
  --comparison-operator LessThanThreshold --treat-missing-data notBreaching

now=$(( $(date +%s) * 1000 ))
aws_local logs put-log-events --log-group-name /kp/settlement-api --log-stream-name api-7f3c --log-events \
  "timestamp=$now,message=level=INFO code=SETTLED batch=B-90000" \
  "timestamp=$now,message=level=ERROR code=SETTLE_TIMEOUT batch=B-90001 merchant=m-12" >/dev/null

echo "Saturday's monitoring gap is reproduced: errors are logged, nobody is paged."
