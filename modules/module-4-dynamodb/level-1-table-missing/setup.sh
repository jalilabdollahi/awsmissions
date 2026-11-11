#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# Two neighbours exist in the account so that list-tables is not empty, and one
# of them has a deceptively similar name.
aws_local dynamodb create-table --table-name harvest-farms \
  --attribute-definitions AttributeName=farmId,AttributeType=S \
  --key-schema AttributeName=farmId,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST >/dev/null

aws_local dynamodb create-table --table-name harvest-order \
  --attribute-definitions AttributeName=orderId,AttributeType=S \
  --key-schema AttributeName=orderId,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST >/dev/null

aws_local dynamodb put-item --table-name harvest-farms \
  --item '{"farmId":{"S":"farm-oakridge"},"name":{"S":"Oakridge Co-op"}}'

echo "order-ingest is up. DynamoDB says: ResourceNotFoundException on harvest-orders."
