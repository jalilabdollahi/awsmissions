#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

aws_local dynamodb create-table   --table-name MissionTable   --attribute-definitions AttributeName=id,AttributeType=S AttributeName=category,AttributeType=S   --key-schema AttributeName=id,KeyType=HASH   --billing-mode PAY_PER_REQUEST   --global-secondary-indexes '[{"IndexName":"category-index","KeySchema":[{"AttributeName":"category","KeyType":"HASH"}],"Projection":{"ProjectionType":"KEYS_ONLY"}}]' >/dev/null 2>&1 || true
echo "Broken table created: category-index projection is KEYS_ONLY"
