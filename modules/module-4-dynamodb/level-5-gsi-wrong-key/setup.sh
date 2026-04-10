#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

aws_local dynamodb create-table   --table-name MissionTable   --attribute-definitions AttributeName=id,AttributeType=S AttributeName=username,AttributeType=S AttributeName=email,AttributeType=S   --key-schema AttributeName=id,KeyType=HASH   --billing-mode PAY_PER_REQUEST   --global-secondary-indexes '[{"IndexName":"email-index","KeySchema":[{"AttributeName":"username","KeyType":"HASH"}],"Projection":{"ProjectionType":"ALL"}}]' >/dev/null 2>&1 || true
echo "Broken table created: email-index uses username instead of email"
