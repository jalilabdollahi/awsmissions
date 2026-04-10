#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
aws_local dynamodb describe-table --table-name MissionTable >/dev/null
echo "success"
