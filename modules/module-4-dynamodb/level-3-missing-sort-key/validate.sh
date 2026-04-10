#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
range="$(aws_local dynamodb describe-table --table-name MissionTable --query 'Table.KeySchema[?KeyType==`RANGE`].AttributeName | [0]' --output text)"
[ "$range" = "createdAt" ]
echo "success"
