#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

shards="$(aws_local kinesis describe-stream-summary --stream-name pageviews --query StreamDescriptionSummary.OpenShardCount --output text 2>/dev/null || true)"
if [ "$shards" != "2" ]; then
  echo "The pageviews stream is not as the apps expect it (open shards: '${shards:-missing}'). It must stay as it was: the fix is on the Firehose side."
  exit 1
fi

desc="$(aws_local firehose describe-delivery-stream --delivery-stream-name pageview-archive --output json 2>/dev/null || true)"
if [ -z "$desc" ]; then
  echo "There is no delivery stream named pageview-archive. The compliance runbooks use that name."
  exit 1
fi
type="$(printf '%s' "$desc" | jq -r '.DeliveryStreamDescription.DeliveryStreamType')"
if [ "$type" != "KinesisStreamAsSource" ]; then
  echo "pageview-archive is a $type delivery stream: it only receives what is sent to it directly, and the apps publish to the Kinesis stream."
  exit 1
fi
src="$(printf '%s' "$desc" | jq -r '.DeliveryStreamDescription.Source.KinesisStreamSourceDescription.KinesisStreamARN // empty')"
case "$src" in
  *:stream/pageviews) ;;
  *) echo "pageview-archive reads from '${src:-nothing}', not from the pageviews stream."; exit 1 ;;
esac

# Publish like an app does (to Kinesis only) and wait for the archive to receive it.
run="$(date +%s)"
for n in 1 2 3; do
  aws_local kinesis put-record --stream-name pageviews --partition-key "visitor-$run-$n" \
    --data "$(printf '{"visitor":"probe-%s-%s","path":"/pricing"}\n' "$run" "$n" | base64)" >/dev/null
done

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
count_found() {
  local n=0 key
  for key in $(aws_local s3api list-objects-v2 --bucket pinecrest-archive --prefix raw/ \
                 --query 'Contents[].Key' --output text 2>/dev/null | tr '\t' '\n' | grep -v '^None$' || true); do
    aws_local s3api get-object --bucket pinecrest-archive --key "$key" "$tmp" >/dev/null 2>&1 || continue
    n=$((n + $(grep -c "probe-$run-" "$tmp" || true)))
  done
  echo "$n"
}
got=0
i=0
while [ "$i" -lt 20 ]; do
  got="$(count_found)"
  [ "$got" -ge 3 ] && break
  sleep 2
  i=$((i + 1))
done
if [ "$got" -lt 3 ]; then
  echo "Only $got of the 3 events published to pageviews reached s3://pinecrest-archive/raw/ within about 40 seconds."
  exit 1
fi

echo "All three events published to the pageviews stream arrived in the archive bucket under raw/."
