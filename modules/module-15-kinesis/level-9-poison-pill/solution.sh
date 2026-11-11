#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

uuid="$(aws_local lambda list-event-source-mappings --function-name vitals-alerter \
  --query 'EventSourceMappings[0].UUID' --output text)"
aws_local lambda update-event-source-mapping --uuid "$uuid" \
  --maximum-retry-attempts 2 --bisect-batch-on-function-error \
  --destination-config "{\"OnFailure\":{\"Destination\":\"arn:aws:sqs:us-east-1:${ACCOUNT_ID}:vitals-dead-letters\"}}" >/dev/null
