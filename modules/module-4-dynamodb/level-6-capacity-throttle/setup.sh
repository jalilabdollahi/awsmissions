#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local dynamodb create-table --table-name pulsewire-readings \
  --attribute-definitions AttributeName=turbineId,AttributeType=S AttributeName=readAt,AttributeType=N \
  --key-schema AttributeName=turbineId,KeyType=HASH AttributeName=readAt,KeyType=RANGE \
  --billing-mode PROVISIONED \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 >/dev/null

aws_local dynamodb put-item --table-name pulsewire-readings \
  --item '{"turbineId":{"S":"wt-017"},"readAt":{"N":"1767225600"},"rpm":{"N":"14"}}'

echo "pulsewire-readings runs at 5/5 units with nothing to adjust them."
