#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
index="$(aws_local dynamodb describe-table --table-name MissionTable --query 'Table.GlobalSecondaryIndexes[0].IndexName' --output text)"
[ "$index" = "email-index" ]
echo "success"
