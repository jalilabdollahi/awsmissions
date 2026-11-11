#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local dynamodb update-table --table-name shelfwise-books \
  --global-secondary-index-updates '[{"Delete":{"IndexName":"category-index"}}]' >/dev/null
wait_for "category-index removal" 60 \
  test -z "$(aws_local dynamodb describe-table --table-name shelfwise-books \
  --query 'Table.GlobalSecondaryIndexes[].IndexName' --output text | sed 's/None//')"

aws_local dynamodb update-table --table-name shelfwise-books \
  --attribute-definitions AttributeName=category,AttributeType=S AttributeName=price,AttributeType=N \
  --global-secondary-index-updates \
  '[{"Create":{"IndexName":"category-index","KeySchema":[{"AttributeName":"category","KeyType":"HASH"},{"AttributeName":"price","KeyType":"RANGE"}],"Projection":{"ProjectionType":"INCLUDE","NonKeyAttributes":["title","author"]}}}]' >/dev/null
wait_for "category-index ACTIVE" 60 \
  test "$(aws_local dynamodb describe-table --table-name shelfwise-books \
  --query 'Table.GlobalSecondaryIndexes[0].IndexStatus' --output text)" = "ACTIVE"
