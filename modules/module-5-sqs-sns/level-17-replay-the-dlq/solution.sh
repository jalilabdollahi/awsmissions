#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local sqs start-message-move-task \
  --source-arn "arn:aws:sqs:us-east-1:${ACCOUNT_ID}:crescent-invoices-dlq" \
  --destination-arn "arn:aws:sqs:us-east-1:${ACCOUNT_ID}:crescent-invoices"
