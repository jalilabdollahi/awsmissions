#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

aws_local dynamodb create-table   --table-name MissionTable   --attribute-definitions AttributeName=userId,AttributeType=S AttributeName=createdAt,AttributeType=S   --key-schema AttributeName=userId,KeyType=HASH AttributeName=createdAt,KeyType=RANGE   --billing-mode PAY_PER_REQUEST >/dev/null 2>&1 || true
echo "Broken state prepared: application uses Scan instead of Query"
