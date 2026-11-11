#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

stamp="$(date +%s)"
batch="$(jq -cn --arg s "$stamp" '[
  {Data:("hamburg-scan-1-"+$s|@base64),PartitionKey:"parcel-881"},
  {Data:("hamburg-scan-2-"+$s|@base64),PartitionKey:"parcel-882"},
  {Data:("hamburg-scan-3-"+$s|@base64),PartitionKey:"parcel-883"}]')"

set +e
out="$(aws_as_user scan-gateway kinesis put-records --stream-name parcel-scans --records "$batch" 2>&1)"
rc=$?
set -e
if [ "$rc" -ne 0 ]; then
  echo "scan-gateway still cannot send a batch to parcel-scans."
  echo "Kinesis said: $(printf '%s' "$out" | tail -1)"
  exit 1
fi
failed="$(printf '%s' "$out" | jq -r '.FailedRecordCount')"
if [ "$failed" != "0" ]; then
  echo "The batch was accepted but $failed record(s) failed."
  exit 1
fi

# The batch really arrived.
found="$(aws_local kinesis get-shard-iterator --stream-name parcel-scans --shard-id shardId-000000000000 \
  --shard-iterator-type TRIM_HORIZON --query ShardIterator --output text)"
seen="$(aws_local kinesis get-records --shard-iterator "$found" --query 'Records[].Data' --output json | jq -r --arg s "$stamp" '[.[] | @base64d | select(endswith($s))] | length')"
if [ "$seen" != "3" ]; then
  echo "Only $seen of the 3 scans from the test batch reached parcel-scans."
  exit 1
fi

if aws_as_user scan-gateway kinesis put-records --stream-name parcel-billing --records "$batch" >/dev/null 2>&1; then
  echo "Scans now work, but scan-gateway can also write to parcel-billing. Scope the permission to the parcel-scans stream only."
  exit 1
fi
if aws_as_user scan-gateway kinesis get-shard-iterator --stream-name parcel-scans --shard-id shardId-000000000000 \
     --shard-iterator-type LATEST >/dev/null 2>&1; then
  echo "Scans now work, but scan-gateway can also read parcel-scans back. Scanners only produce data; give them write actions only."
  exit 1
fi

echo "scan-gateway can send batches to parcel-scans, and only there, write-only. Hamburg is scanning."
