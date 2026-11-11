#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# Unmute the alarm and aim it at the topic the pager app is subscribed to.
sed -e 's/"ActionsEnabled": false/"ActionsEnabled": true/' \
    -e 's/halcyon-oncall-legacy/halcyon-oncall/' alarm.json > alarm.fixed
mv alarm.fixed alarm.json
aws_local cloudwatch put-metric-alarm --cli-input-json file://alarm.json
