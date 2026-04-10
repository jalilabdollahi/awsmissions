#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
type="$(aws_local dynamodb describe-table --table-name MissionTable --query 'Table.AttributeDefinitions[?AttributeName==`userId`].AttributeType | [0]' --output text)"
[ "$type" = "S" ]
echo "success"
