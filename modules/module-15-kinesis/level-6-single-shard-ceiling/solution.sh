#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# One call can at most double the shard count, so go 1 -> 2 -> 4.
aws_local kinesis update-shard-count --stream-name charger-heartbeats \
  --target-shard-count 2 --scaling-type UNIFORM_SCALING >/dev/null
wait_for "stream active" 60 bash -c "[ \"\$(aws --endpoint-url=$AWS_ENDPOINT_URL kinesis describe-stream-summary --stream-name charger-heartbeats --query StreamDescriptionSummary.StreamStatus --output text)\" = ACTIVE ]"
aws_local kinesis update-shard-count --stream-name charger-heartbeats \
  --target-shard-count 4 --scaling-type UNIFORM_SCALING >/dev/null
