#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

if ! aws_local firehose describe-delivery-stream --delivery-stream-name clickstream-to-lake >/dev/null 2>&1; then
  echo "The delivery stream clickstream-to-lake no longer exists. Producers write to it by name: fix it, do not delete it."
  exit 1
fi

run="$(date +%s)"
aws_local firehose put-record --delivery-stream-name clickstream-to-lake \
  --record "Data=$(printf '{"page":"/checkout","visitor":"probe-%s"}\n' "$run" | base64)" >/dev/null

day="$(date -u +%Y-%m-%d)"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
found=""
i=0
while [ "$i" -lt 18 ]; do
  for key in $(aws_local s3api list-objects-v2 --bucket harborview-datalake --prefix "clicks/dt=$day/" \
                 --query 'Contents[].Key' --output text 2>/dev/null | tr '\t' '\n' | grep -v '^None$' || true); do
    aws_local s3api get-object --bucket harborview-datalake --key "$key" "$tmp" >/dev/null 2>&1 || continue
    if grep -q "probe-$run" "$tmp"; then found="$key"; break; fi
  done
  [ -n "$found" ] && break
  sleep 2
  i=$((i + 1))
done

if [ -z "$found" ]; then
  elsewhere=""
  for b in $(aws_local s3api list-buckets --query 'Buckets[].Name' --output text); do
    if [ "$b" != "harborview-datalake" ]; then
      for key in $(aws_local s3api list-objects-v2 --bucket "$b" --query 'Contents[].Key' --output text 2>/dev/null | tr '\t' '\n' | grep -v '^None$' || true); do
        aws_local s3api get-object --bucket "$b" --key "$key" "$tmp" >/dev/null 2>&1 || continue
        if grep -q "probe-$run" "$tmp"; then elsewhere="s3://$b/$key"; fi
      done
    fi
  done
  if [ -n "$elsewhere" ]; then
    echo "The test event was delivered, but to $elsewhere, not to harborview-datalake under clicks/dt=$day/."
  else
    echo "The test event did not show up under s3://harborview-datalake/clicks/dt=$day/ within about 35 seconds."
  fi
  exit 1
fi

echo "The test event arrived at s3://harborview-datalake/$found, where the Athena table looks."
