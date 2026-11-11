#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local dynamodb create-table --table-name parcelo-orders \
  --attribute-definitions AttributeName=orderId,AttributeType=S \
  --key-schema AttributeName=orderId,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST >/dev/null

aws_local dynamodb put-item --table-name parcelo-orders --item '{
  "orderId":{"S":"ord-1042"},"status":{"S":"PACKED"},"version":{"N":"7"},
  "customerId":{"S":"cust-318"},"lineItems":{"L":[{"S":"cable x2"},{"S":"adapter x1"}]}}'
aws_local dynamodb put-item --table-name parcelo-orders --item '{
  "orderId":{"S":"ord-1043"},"status":{"S":"SHIPPED"},"version":{"N":"3"},
  "trackingNo":{"S":"TRK-OLD-777"},"customerId":{"S":"cust-902"},"lineItems":{"L":[{"S":"lamp x1"}]}}'

echo "parcelo-orders has two orders. ship-orders.sh fails on both."
