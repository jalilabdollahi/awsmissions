#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

STREAM=charger-heartbeats
if ! aws_local kinesis describe-stream-summary --stream-name "$STREAM" >/dev/null 2>&1; then
  echo "charger-heartbeats does not exist any more. Scale the stream; do not delete it."
  exit 1
fi

open="$(aws_local kinesis list-shards --stream-name "$STREAM" \
  --query 'Shards[?SequenceNumberRange.EndingSequenceNumber==`null`].ShardId' --output json)"
count="$(printf '%s' "$open" | jq 'length')"
if [ "$count" -lt 3 ]; then
  echo "charger-heartbeats has $count open shard(s), which accept about $count MB/s in total. A 3 MB/s peak needs at least 3."
  exit 1
fi
if [ "$count" -gt 6 ]; then
  echo "charger-heartbeats has $count open shards. Finance allows at most 6; you are paying for capacity nobody asked for."
  exit 1
fi

# Behaviour: fresh heartbeats from many chargers are accepted and spread over the open shards.
batch="$(jq -cn '[range(0;40) | {Data:("{\"charger\":\"probe-\(.)\"}"|@base64), PartitionKey:"probe-charger-\(.)"}]')"
resp="$(aws_local kinesis put-records --stream-name "$STREAM" --records "$batch" --output json)"
if [ "$(printf '%s' "$resp" | jq '.FailedRecordCount')" != "0" ]; then
  echo "Some heartbeats were rejected by Kinesis."
  exit 1
fi
used="$(printf '%s' "$resp" | jq '[.Records[].ShardId] | unique | length')"
if [ "$used" -lt 3 ]; then
  echo "Heartbeats from 40 different chargers only reached $used shard(s). Capacity that traffic cannot reach does not help."
  exit 1
fi

# The history must have survived, including on shards that were closed by the resharding.
seeded=0
for shard in $(aws_local kinesis list-shards --stream-name "$STREAM" --query 'Shards[].ShardId' --output text); do
  it="$(aws_local kinesis get-shard-iterator --stream-name "$STREAM" --shard-id "$shard" --shard-iterator-type TRIM_HORIZON --query ShardIterator --output text)"
  n="$(aws_local kinesis get-records --shard-iterator "$it" --limit 1000 --query 'Records[].Data' --output json \
    | jq '[.[] | @base64d | fromjson | select(.seed == true)] | length')"
  seeded=$((seeded + n))
done
if [ "$seeded" != "4" ]; then
  echo "Only $seeded of the 4 heartbeats that were already in the stream can be found. Scale the existing stream instead of replacing it."
  exit 1
fi

echo "charger-heartbeats now has $count open shards (about $count MB/s), 40 test heartbeats were spread over $used of them, and the original history is intact."
