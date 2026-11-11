#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

desc="$(aws_local firehose describe-delivery-stream --delivery-stream-name fraud-signals-to-s3 --output json 2>/dev/null || true)"
if [ -z "$desc" ]; then
  echo "The delivery stream fraud-signals-to-s3 no longer exists. The gateways send to it by name: tune it, do not delete it."
  exit 1
fi
interval="$(printf '%s' "$desc" | jq -r '.DeliveryStreamDescription.Destinations[0].ExtendedS3DestinationDescription.BufferingHints.IntervalInSeconds')"
if [ "$interval" -lt 5 ]; then
  echo "The buffer interval is ${interval}s: Firehose would write a new object almost every second, which is the tiny-files swarm the analysis jobs cannot handle."
  exit 1
fi

run="$(date +%s)"
aws_local firehose put-record --delivery-stream-name fraud-signals-to-s3 \
  --record "Data=$(printf '{"signal":"card-velocity","card":"probe-%s"}\n' "$run" | base64)" >/dev/null

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
found=""; plain=""
i=0
while [ "$i" -lt 20 ]; do
  for key in $(aws_local s3api list-objects-v2 --bucket aldermoor-fraud-landing --prefix signals/ \
                 --query 'Contents[].Key' --output text 2>/dev/null | tr '\t' '\n' | grep -v '^None$' || true); do
    aws_local s3api get-object --bucket aldermoor-fraud-landing --key "$key" "$tmp" >/dev/null 2>&1 || continue
    if [ "$(head -c 2 "$tmp" | od -An -tx1 | tr -d ' \n')" = "1f8b" ]; then
      if gzip -dc "$tmp" 2>/dev/null | grep -q "probe-$run"; then found="$key"; break; fi
    elif grep -q "probe-$run" "$tmp"; then
      plain="$key"
    fi
  done
  [ -n "$found" ] && break
  sleep 2
  i=$((i + 1))
done

if [ -n "$found" ]; then
  echo "The fraud signal arrived as a gzip-compressed object (s3://aldermoor-fraud-landing/$found) within the time budget."
  exit 0
fi
if [ -n "$plain" ]; then
  echo "The signal arrived quickly (s3://aldermoor-fraud-landing/$plain) but as plain text. The storage team wants it compressed."
else
  echo "The signal was not delivered within about 40 seconds (buffer interval is currently ${interval}s)."
fi
exit 1
