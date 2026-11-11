#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

sed 's/"TreatMissingData": "missing"/"TreatMissingData": "notBreaching"/' alarm.json > alarm.json.tmp
mv alarm.json.tmp alarm.json
aws_local cloudwatch put-metric-alarm --cli-input-json file://alarm.json
