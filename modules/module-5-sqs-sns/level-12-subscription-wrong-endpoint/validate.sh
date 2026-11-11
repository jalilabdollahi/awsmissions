#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

topic_arn="arn:aws:sns:us-east-1:${ACCOUNT_ID}:quartz-invoice-events"
prod="$(aws_local sqs get-queue-url --queue-name quartz-invoices-prod --query QueueUrl --output text 2>/dev/null || true)"
staging="$(aws_local sqs get-queue-url --queue-name quartz-invoices-staging --query QueueUrl --output text 2>/dev/null || true)"
if [ -z "$prod" ] || [ -z "$staging" ]; then
  echo "Both quartz-invoices-prod and quartz-invoices-staging must exist; fix the subscription, not the queues."
  exit 1
fi

invoice="INV-$(date +%s)-$$"
aws_local sns publish --topic-arn "$topic_arn" --message "$invoice" >/dev/null

has_invoice() {
  aws_local sqs receive-message --queue-url "$1" --max-number-of-messages 10 --visibility-timeout 0 \
    --query 'Messages[].Body' --output text 2>/dev/null | grep -q "$invoice"
}
if ! wait_for "prod delivery" 8 has_invoice "$prod"; then
  echo "The invoice never reached quartz-invoices-prod. Check where the subscription sends its messages."
  exit 1
fi
sleep 1
if has_invoice "$staging"; then
  echo "The invoice also reached quartz-invoices-staging. Production events must not flow into the test environment: remove the old subscription."
  exit 1
fi

echo "Invoice events go to quartz-invoices-prod only. Printing resumes."
