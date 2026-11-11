#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

topic="$(aws_local sns create-topic --name quartz-invoice-events --query TopicArn --output text)"
aws_local sqs create-queue --queue-name quartz-invoices-prod >/dev/null
aws_local sqs create-queue --queue-name quartz-invoices-staging >/dev/null

# Copy-paste from the staging runbook.
aws_local sns subscribe --topic-arn "$topic" --protocol sqs \
  --notification-endpoint "arn:aws:sqs:us-east-1:${ACCOUNT_ID}:quartz-invoices-staging" >/dev/null

echo "quartz-invoice-events delivers to quartz-invoices-staging."
