#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local dynamodb create-table --table-name harvest-orders \
  --attribute-definitions AttributeName=farmId,AttributeType=S AttributeName=orderedAt,AttributeType=N \
  --key-schema AttributeName=farmId,KeyType=HASH AttributeName=orderedAt,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST
