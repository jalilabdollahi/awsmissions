#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local dynamodb create-table --table-name greenroom-articles \
  --attribute-definitions AttributeName=slug,AttributeType=S \
  --key-schema AttributeName=slug,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST >/dev/null

aws_local dynamodb put-item --table-name greenroom-articles \
  --item '{"slug":{"S":"city-budget-vote"},"headline":{"S":"Council votes on budget"},"status":{"S":"draft"}}'
aws_local dynamodb put-item --table-name greenroom-articles \
  --item '{"slug":{"S":"harbor-closure"},"headline":{"S":"Harbor closed for repairs"},"status":{"S":"published"}}'

echo "greenroom-articles holds two articles; the audit consumer has nothing to read."
