#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local cloudwatch put-metric-alarm --cli-input-json "file://$MISSION_DIR/workspace/alarm.json"

# The volume is currently almost empty: 480 GB free.
aws_local cloudwatch put-metric-data --namespace Nimbus/Storage --metric-name FreeSpaceGB \
  --dimensions VolumeId=data-01 --value 480

echo "nimbus-data-volume-low-space is deployed. It shouts when there is lots of space."
