#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

if ! aws_local kinesis describe-stream-summary --stream-name thermowave-readings >/dev/null 2>&1; then
  echo "The stream thermowave-readings is gone. The stream was never the problem: restore it and fix the function instead."
  exit 1
fi
streams="$(aws_local kinesis list-streams --query 'length(StreamNames)' --output text)"
if [ "$streams" != "1" ]; then
  echo "There are $streams streams in the account, expected only the original one. Do not create new streams to match a typo; point the function at the real one."
  exit 1
fi

device="probe-$(date +%s)"
out="$(mktemp)"
trap 'rm -f "$out"' EXIT
aws_local lambda invoke --function-name thermo-ingest --cli-binary-format raw-in-base64-out \
  --payload "{\"device_id\":\"$device\",\"temp_c\":21.5}" "$out" > "$out.meta" 2>&1 || true
if grep -q FunctionError "$out.meta" 2>/dev/null; then
  echo "thermo-ingest still fails when a reading arrives: $(jq -r '.errorMessage // "unknown error"' "$out" 2>/dev/null)"
  rm -f "$out.meta"
  exit 1
fi
rm -f "$out.meta"

shard="$(jq -r '.shard' "$out")"
seq="$(jq -r '.sequence' "$out")"
it="$(aws_local kinesis get-shard-iterator --stream-name thermowave-readings --shard-id "$shard" \
  --shard-iterator-type AT_SEQUENCE_NUMBER --starting-sequence-number "$seq" --query ShardIterator --output text)"
rec="$(aws_local kinesis get-records --shard-iterator "$it" --limit 1 --query 'Records[0].Data' --output text | jq -R -r '@base64d' 2>/dev/null || true)"
got="$(printf '%s' "$rec" | jq -r '.device_id // empty' 2>/dev/null || true)"
if [ "$got" != "$device" ]; then
  echo "The function says it wrote the reading, but it is not in thermowave-readings."
  exit 1
fi
channel="$(printf '%s' "$rec" | jq -r '.channel')"
if [ "$channel" != "stable" ]; then
  echo "Readings arrive, but they are tagged with firmware channel '$channel' instead of 'stable'. Updating the environment replaces the whole variable set, so the other variables need to be kept."
  exit 1
fi

echo "A fresh reading from $device landed in thermowave-readings, still tagged with the stable channel. The model is getting data again."
