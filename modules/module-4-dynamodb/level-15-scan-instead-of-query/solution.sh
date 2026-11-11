#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local dynamodb update-table --table-name orbit-shipments \
  --attribute-definitions AttributeName=region,AttributeType=S AttributeName=shippedAt,AttributeType=N \
  --global-secondary-index-updates \
  '[{"Create":{"IndexName":"by-region-time","KeySchema":[{"AttributeName":"region","KeyType":"HASH"},{"AttributeName":"shippedAt","KeyType":"RANGE"}],"Projection":{"ProjectionType":"ALL"}}}]' >/dev/null
wait_for "by-region-time ACTIVE" 60 \
  test "$(aws_local dynamodb describe-table --table-name orbit-shipments \
  --query 'Table.GlobalSecondaryIndexes[0].IndexStatus' --output text)" = "ACTIVE"

cat > report-policy.json <<POL
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "QueryShipmentsOnly",
    "Effect": "Allow",
    "Action": "dynamodb:Query",
    "Resource": [
      "arn:aws:dynamodb:us-east-1:${ACCOUNT_ID}:table/orbit-shipments",
      "arn:aws:dynamodb:us-east-1:${ACCOUNT_ID}:table/orbit-shipments/index/by-region-time"
    ]
  }]
}
POL
aws_local iam put-user-policy --user-name orbit-report-svc --policy-name report-reads \
  --policy-document file://report-policy.json
