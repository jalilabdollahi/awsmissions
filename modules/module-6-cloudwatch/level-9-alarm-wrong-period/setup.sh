#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local cloudwatch put-metric-alarm --cli-input-json "file://$MISSION_DIR/workspace/alarm.json"

echo "brightside-bounce-spike evaluates in 300 second windows."
