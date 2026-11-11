#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local sns subscribe \
  --topic-arn "arn:aws:sns:us-east-1:${ACCOUNT_ID}:bluebird-checkout-events" \
  --protocol sqs \
  --notification-endpoint "arn:aws:sqs:us-east-1:${ACCOUNT_ID}:bluebird-loyalty"
