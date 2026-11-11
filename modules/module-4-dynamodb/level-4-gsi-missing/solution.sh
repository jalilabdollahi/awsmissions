#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local dynamodb update-table --table-name cartwheel-members \
  --attribute-definitions AttributeName=email,AttributeType=S \
  --global-secondary-index-updates \
  '[{"Create":{"IndexName":"email-index","KeySchema":[{"AttributeName":"email","KeyType":"HASH"}],"Projection":{"ProjectionType":"ALL"}}}]' >/dev/null

wait_for "email-index to become ACTIVE" 60 \
  test "$(aws_local dynamodb describe-table --table-name cartwheel-members \
  --query 'Table.GlobalSecondaryIndexes[0].IndexStatus' --output text)" = "ACTIVE"
