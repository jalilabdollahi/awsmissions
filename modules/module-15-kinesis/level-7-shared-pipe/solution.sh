#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

STREAM_ARN="arn:aws:kinesis:us-east-1:${ACCOUNT_ID}:stream/trade-ticks"
consumer_arn="$(aws_local kinesis register-stream-consumer --stream-arn "$STREAM_ARN" \
  --consumer-name risk-scorer-efo --query Consumer.ConsumerARN --output text)"
wait_for "consumer ACTIVE" 60 bash -c "[ \"\$(aws --endpoint-url=$AWS_ENDPOINT_URL kinesis describe-stream-consumer --consumer-arn '$consumer_arn' --query ConsumerDescription.ConsumerStatus --output text)\" = ACTIVE ]"

old="$(aws_local lambda list-event-source-mappings --function-name risk-scorer \
  --query 'EventSourceMappings[0].UUID' --output text)"
aws_local lambda create-event-source-mapping --function-name risk-scorer \
  --event-source-arn "$consumer_arn" --starting-position LATEST \
  --batch-size 50 --maximum-batching-window-in-seconds 1 >/dev/null
aws_local lambda delete-event-source-mapping --uuid "$old" >/dev/null
