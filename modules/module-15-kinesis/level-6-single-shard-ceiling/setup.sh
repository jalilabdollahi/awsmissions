#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local kinesis create-stream --stream-name charger-heartbeats --shard-count 1 >/dev/null
wait_for "stream charger-heartbeats" 20 aws_local kinesis describe-stream-summary --stream-name charger-heartbeats

for charger in 101 102 103 104; do
  aws_local kinesis put-record --stream-name charger-heartbeats --partition-key "charger-$charger" \
    --data "$(printf '{"charger":"%s","state":"idle","seed":true}' "$charger" | base64)" >/dev/null
done

echo "charger-heartbeats has a single shard holding four heartbeats, and 2,000 chargers are on their way."
