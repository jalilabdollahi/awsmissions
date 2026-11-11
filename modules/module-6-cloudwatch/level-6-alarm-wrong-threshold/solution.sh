#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

sed 's/"Threshold": 900,/"Threshold": 90,/' alarm.json > alarm.json.new
mv alarm.json.new alarm.json
aws_local cloudwatch put-metric-alarm --cli-input-json file://alarm.json
