#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

aws_local dynamodb create-table   --table-name MissionTable   --attribute-definitions AttributeName=id,AttributeType=S AttributeName=createdAt,AttributeType=S AttributeName=status,AttributeType=S   --key-schema AttributeName=id,KeyType=HASH AttributeName=createdAt,KeyType=RANGE   --billing-mode PAY_PER_REQUEST >/dev/null 2>&1 || true
echo "Broken table created: status-index LSI is missing"
