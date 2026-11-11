#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

STREAM=order-events
run="r$(date +%s)"
payload="$(jq -cn --arg run "$run" '{events: [
  range(7001; 7013) as $n
  | ["created","paid","shipped"][] as $t
  | {run:$run, order_id:("Q-\($n)"), customer_id:("cust-\($n % 5)"), type:$t}]}')"

out="$(mktemp)"
trap 'rm -f "$out" "$out.meta" "$out.recs"' EXIT
printf '%s' "$payload" > "$out.in"
aws_local lambda invoke --function-name order-publisher --cli-binary-format raw-in-base64-out \
  --payload "file://$out.in" "$out" > "$out.meta" 2>&1 || true
rm -f "$out.in"
if grep -q FunctionError "$out.meta"; then
  echo "order-publisher failed: $(jq -r '.errorMessage // "unknown error"' "$out")"
  exit 1
fi
if [ "$(jq -r '.failed' "$out")" != "0" ]; then
  echo "Some records were rejected by Kinesis ($(jq -r '.failed' "$out") failed)."
  exit 1
fi

# Collect what really landed, per shard, for this run only.
: > "$out.recs"
for shard in $(aws_local kinesis list-shards --stream-name "$STREAM" --query 'Shards[?SequenceNumberRange.EndingSequenceNumber==`null`].ShardId' --output text); do
  it="$(aws_local kinesis get-shard-iterator --stream-name "$STREAM" --shard-id "$shard" --shard-iterator-type TRIM_HORIZON --query ShardIterator --output text)"
  aws_local kinesis get-records --shard-iterator "$it" --limit 1000 --output json \
    | jq -c --arg shard "$shard" --arg run "$run" \
        '.Records[] | {shard:$shard, key:.PartitionKey, body:(.Data|@base64d|fromjson)} | select(.body.run == $run) | {shard, key, order:.body.order_id, type:.body.type}' >> "$out.recs"
done

total="$(wc -l < "$out.recs" | tr -d ' ')"
if [ "$total" != "36" ]; then
  echo "Expected the 36 test events to be on the stream, found $total."
  exit 1
fi
shards_used="$(jq -rs '[.[].shard] | unique | length' "$out.recs")"
if [ "$shards_used" -lt 3 ]; then
  echo "The 36 test events landed on only $shards_used shard(s) of order-events. The load is still concentrated."
  exit 1
fi
biggest="$(jq -rs 'group_by(.shard) | map(length) | max' "$out.recs")"
if [ "$biggest" -gt 20 ]; then
  echo "One shard received $biggest of the 36 test events. The load is still badly skewed."
  exit 1
fi
split="$(jq -rs 'group_by(.order) | map(select((map(.shard) | unique | length) > 1)) | length' "$out.recs")"
if [ "$split" != "0" ]; then
  echo "$split order(s) had events written to different shards. The warehouse can no longer see each order's events in order: events of one order must share a partition key."
  exit 1
fi

echo "The 36 test events were spread over $shards_used shards (busiest shard: $biggest) and every order stayed on a single shard."
