#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
attr="$(aws_local dynamodb describe-table --table-name MissionTable --query 'Table.GlobalSecondaryIndexes[0].KeySchema[0].AttributeName' --output text)"
[ "$attr" = "email" ]
echo "success"
