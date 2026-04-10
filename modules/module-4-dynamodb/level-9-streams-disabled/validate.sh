#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
status="$(aws_local dynamodb describe-table --table-name MissionTable --query 'Table.StreamSpecification.StreamEnabled' --output text)"
[ "$status" = "True" ]
echo "success"
