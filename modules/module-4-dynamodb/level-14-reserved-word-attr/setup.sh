#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local dynamodb create-table --table-name deskly-tickets \
  --attribute-definitions AttributeName=ticketId,AttributeType=S \
  --key-schema AttributeName=ticketId,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST >/dev/null

aws_local dynamodb put-item --table-name deskly-tickets --item '{
  "ticketId":{"S":"tk-77"},"subject":{"S":"Refund for double charge"},"status":{"S":"RESOLVED"},
  "agent":{"S":"mila"},"reopenCount":{"N":"1"}}'
aws_local dynamodb put-item --table-name deskly-tickets --item '{
  "ticketId":{"S":"tk-78"},"subject":{"S":"Password reset loop"},"status":{"S":"OPEN"},
  "agent":{"S":"jonas"},"reopenCount":{"N":"0"}}'

echo "tk-77 is resolved but cannot be closed. close-ticket.sh throws a ValidationException."
