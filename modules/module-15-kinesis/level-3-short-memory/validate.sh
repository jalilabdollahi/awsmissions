#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

summary="$(aws_local kinesis describe-stream-summary --stream-name meter-reads --output json 2>/dev/null || true)"
if [ -z "$summary" ]; then
  echo "meter-reads no longer exists. Replaying a stream that was deleted is not possible: restore the original behaviour without recreating it."
  exit 1
fi

# The seeded reads must still be there: proof that the stream was changed, not replaced.
it="$(aws_local kinesis get-shard-iterator --stream-name meter-reads --shard-id shardId-000000000000 \
  --shard-iterator-type TRIM_HORIZON --query ShardIterator --output text)"
seeded="$(aws_local kinesis get-records --shard-iterator "$it" --query 'Records[].Data' --output json \
  | jq '[.[] | @base64d | fromjson | select(.seed == true)] | length')"
if [ "$seeded" != "3" ]; then
  echo "The reads that were already in meter-reads are missing ($seeded of 3 found). Do not recreate the stream."
  exit 1
fi

hours="$(printf '%s' "$summary" | jq -r '.StreamDescriptionSummary.RetentionPeriodHours')"
if [ "$hours" -lt 96 ]; then
  echo "meter-reads keeps data for ${hours}h. A three-day outage (72h) plus a day of margin needs more than that."
  exit 1
fi
if [ "$hours" -gt 168 ]; then
  echo "meter-reads keeps data for ${hours}h, which is beyond seven days and into the long-term retention tier finance does not want to pay for."
  exit 1
fi

echo "meter-reads now retains ${hours}h of data, enough to replay after a 72h outage with margin, and it still holds the original reads."
