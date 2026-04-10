#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
aws_local dynamodb put-item   --table-name MissionTable   --item '{"id":{"S":"item-1"},"status":{"S":"updated"}}' >/dev/null
status="$(aws_local dynamodb get-item --table-name MissionTable --key '{"id":{"S":"item-1"}}' --query 'Item.status.S' --output text)"
[ "$status" = "updated" ]
echo "success"
