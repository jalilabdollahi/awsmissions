#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

SQS="arn:aws:sqs:us-east-1:${ACCOUNT_ID}"

# 1. Redrive policy: the real DLQ, three receives, and 30 seconds per parcel.
cat > attrs.json <<JSON
{"VisibilityTimeout":"30","RedrivePolicy":"{\"deadLetterTargetArn\":\"$SQS:pw-sort-jobs-dlq\",\"maxReceiveCount\":\"3\"}"}
JSON
aws_local sqs set-queue-attributes --queue-url "$AWS_ENDPOINT_URL/${ACCOUNT_ID}/pw-sort-jobs" --attributes file://attrs.json

# 2. Page ops whenever anything sits in the DLQ.
aws_local cloudwatch put-metric-alarm --alarm-name pw-dlq-not-empty \
  --namespace AWS/SQS --metric-name ApproximateNumberOfMessagesVisible \
  --dimensions Name=QueueName,Value=pw-sort-jobs-dlq --statistic Maximum --period 60 --evaluation-periods 1 \
  --threshold 0 --comparison-operator GreaterThanThreshold --treat-missing-data notBreaching \
  --alarm-actions "arn:aws:sns:us-east-1:${ACCOUNT_ID}:pw-ops-alerts"
