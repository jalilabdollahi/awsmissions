#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local dynamodb update-table --table-name stockroom-bins \
  --global-secondary-index-updates '[{"Delete":{"IndexName":"sku-index"}}]' >/dev/null
wait_for "old index to disappear" 60 \
  test -z "$(aws_local dynamodb describe-table --table-name stockroom-bins \
  --query 'Table.GlobalSecondaryIndexes[?IndexName==`sku-index`].IndexName' --output text | tr -d 'None')"

aws_local dynamodb update-table --table-name stockroom-bins \
  --attribute-definitions AttributeName=sku,AttributeType=S AttributeName=qty,AttributeType=N \
  --global-secondary-index-updates \
  '[{"Create":{"IndexName":"sku-index","KeySchema":[{"AttributeName":"sku","KeyType":"HASH"},{"AttributeName":"qty","KeyType":"RANGE"}],"Projection":{"ProjectionType":"ALL"}}}]' >/dev/null
wait_for "new index ACTIVE" 60 \
  test "$(aws_local dynamodb describe-table --table-name stockroom-bins \
  --query 'Table.GlobalSecondaryIndexes[0].IndexStatus' --output text)" = "ACTIVE"
