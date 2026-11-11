#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local sqs create-queue --queue-name skyline-receipts >/dev/null
aws_local events put-rule --cli-input-json "file://$MISSION_DIR/workspace/rule.json" >/dev/null
aws_local events put-targets --rule skyline-ticket-sold \
  --targets "Id=receipt-printer,Arn=arn:aws:sqs:us-east-1:${ACCOUNT_ID}:skyline-receipts" >/dev/null

echo "skyline-ticket-sold has a target and a pattern, but ticket events do not arrive."
