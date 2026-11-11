#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local cloudwatch put-metric-alarm --cli-input-json "file://$MISSION_DIR/workspace/alarm.json"

echo "pylon-node-cpu-saturated exists and is applied. It stays green no matter what."
