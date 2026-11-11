#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local dynamodb delete-table --table-name fixline-ticket-events >/dev/null
aws_local dynamodb create-table --table-name fixline-ticket-events \
  --attribute-definitions AttributeName=ticketId,AttributeType=S AttributeName=eventAt,AttributeType=S \
  --key-schema AttributeName=ticketId,KeyType=HASH AttributeName=eventAt,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST
