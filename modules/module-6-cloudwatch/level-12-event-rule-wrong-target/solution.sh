#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local events remove-targets --rule harbor-shipment-created --ids ingest
aws_local events put-targets --rule harbor-shipment-created \
  --targets "Id=ingest,Arn=arn:aws:sqs:us-east-1:${ACCOUNT_ID}:harbor-ingest-prod"
