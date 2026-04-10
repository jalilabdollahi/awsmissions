#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
mode="$(aws_local dynamodb describe-table --table-name MissionTable --query 'Table.BillingModeSummary.BillingMode' --output text 2>/dev/null || true)"
readc="$(aws_local dynamodb describe-table --table-name MissionTable --query 'Table.ProvisionedThroughput.ReadCapacityUnits' --output text)"
writec="$(aws_local dynamodb describe-table --table-name MissionTable --query 'Table.ProvisionedThroughput.WriteCapacityUnits' --output text)"
[ "$mode" = "PAY_PER_REQUEST" ] || { [ "$readc" -ge 5 ] && [ "$writec" -ge 5 ]; }
echo "success"
