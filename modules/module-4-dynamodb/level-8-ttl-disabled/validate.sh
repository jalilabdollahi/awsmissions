#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
status="$(aws_local dynamodb describe-time-to-live --table-name MissionTable --query 'TimeToLiveDescription.TimeToLiveStatus' --output text)"
attr="$(aws_local dynamodb describe-time-to-live --table-name MissionTable --query 'TimeToLiveDescription.AttributeName' --output text)"
[ "$status" = "ENABLED" ]
[ "$attr" = "expiresAt" ]
echo "success"
