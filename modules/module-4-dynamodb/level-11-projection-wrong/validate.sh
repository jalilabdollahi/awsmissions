#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
projection="$(aws_local dynamodb describe-table --table-name MissionTable --query 'Table.GlobalSecondaryIndexes[0].Projection.ProjectionType' --output text)"
[ "$projection" = "ALL" ]
echo "success"
