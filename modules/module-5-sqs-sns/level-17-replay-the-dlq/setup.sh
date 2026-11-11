#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

dlq="$(aws_local sqs create-queue --queue-name crescent-invoices-dlq --query QueueUrl --output text)"
aws_local sqs create-queue --queue-name crescent-invoices \
  --attributes "{\"RedrivePolicy\":\"{\\\"deadLetterTargetArn\\\":\\\"arn:aws:sqs:us-east-1:${ACCOUNT_ID}:crescent-invoices-dlq\\\",\\\"maxReceiveCount\\\":\\\"3\\\"}\"}" >/dev/null

for n in 4101 4102 4103 4104 4105 4106; do
  aws_local sqs send-message --queue-url "$dlq" \
    --message-body "{\"invoice\":\"CR-$n\",\"currency\":\"EUR\",\"state\":\"failed\"}" >/dev/null
done

echo "crescent-invoices-dlq holds six invoices CR-4101 .. CR-4106."
