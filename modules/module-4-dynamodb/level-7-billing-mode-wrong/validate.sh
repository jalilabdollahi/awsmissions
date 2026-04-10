#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
mode="$(aws_local dynamodb describe-table --table-name MissionTable --query 'Table.BillingModeSummary.BillingMode' --output text)"
[ "$mode" = "PAY_PER_REQUEST" ]
echo "success"
