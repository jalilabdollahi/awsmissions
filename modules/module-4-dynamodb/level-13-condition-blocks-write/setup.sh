#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

aws_local dynamodb create-table   --table-name MissionTable   --attribute-definitions AttributeName=id,AttributeType=S   --key-schema AttributeName=id,KeyType=HASH   --billing-mode PAY_PER_REQUEST >/dev/null 2>&1 || true
aws_local dynamodb put-item --table-name MissionTable --item '{"id":{"S":"item-1"},"status":{"S":"old"}}' >/dev/null
echo "Broken state prepared: existing item blocks attribute_not_exists(id) writes"
