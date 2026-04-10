#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
status="$(aws_local dynamodb describe-continuous-backups --table-name MissionTable --query 'ContinuousBackupsDescription.PointInTimeRecoveryDescription.PointInTimeRecoveryStatus' --output text)"
[ "$status" = "ENABLED" ]
echo "success"
