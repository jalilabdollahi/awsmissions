#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

esm="$(aws_local lambda list-event-source-mappings --function-name vitals-alerter --output json | jq '.EventSourceMappings[0] // empty')"
if [ -z "$esm" ]; then
  echo "vitals-alerter has no event source mapping any more. Fix the existing mapping, do not remove it."
  exit 1
fi
if [ "$(printf '%s' "$esm" | jq -r '.State')" != "Enabled" ]; then
  echo "The mapping is not enabled (state: $(printf '%s' "$esm" | jq -r '.State')). Readings cannot flow."
  exit 1
fi

retries="$(printf '%s' "$esm" | jq -r '.MaximumRetryAttempts // -1')"
if [ "$retries" -lt 0 ]; then
  echo "The mapping retries a failing batch forever, so one bad reading blocks the shard for good. Put a limit on retries."
  exit 1
fi
if [ "$retries" -gt 10 ]; then
  echo "The mapping retries a failing batch $retries times. That keeps the shard blocked for far too long; keep the limit small."
  exit 1
fi
if [ "$(printf '%s' "$esm" | jq -r '.BisectBatchOnFunctionError // false')" != "true" ]; then
  echo "When a batch fails, the whole batch is retried and the good readings next to the bad one share its fate. Make the mapping isolate the offender."
  exit 1
fi
dest="$(printf '%s' "$esm" | jq -r '.DestinationConfig.OnFailure.Destination // empty')"
if [ -z "$dest" ]; then
  echo "A reading that exhausts its retries is currently dropped silently. Clinical engineering wants it kept: configure where failed records go."
  exit 1
fi
if [ "$dest" != "arn:aws:sqs:us-east-1:${ACCOUNT_ID}:vitals-dead-letters" ]; then
  echo "Failed records are sent to $dest, but they must end up in the SQS queue vitals-dead-letters."
  exit 1
fi

# Behaviour: good, BAD, good in one go; both good readings must be stored and the bad one must be kept.
run="$(date +%s)"
send() {
  aws_local kinesis put-record --stream-name vitals --partition-key bed-12 \
    --data "$(printf '%s' "$1" | base64)" --query SequenceNumber --output text
}
send "{\"reading_id\":\"probe-a-$run\",\"spo2\":99}" >/dev/null
bad_seq="$(send "{\"reading_id\":\"probe-bad-$run\",\"spo2\":")"
send "{\"reading_id\":\"probe-c-$run\",\"spo2\":93}" >/dev/null

stored() {
  aws_local dynamodb get-item --table-name vitals-processed --key "{\"reading_id\":{\"S\":\"$1\"}}" \
    --query 'Item.reading_id.S' --output text 2>/dev/null || true
}
ok=""
i=0
while [ "$i" -lt 36 ]; do
  if [ "$(stored "probe-a-$run")" = "probe-a-$run" ] && [ "$(stored "probe-c-$run")" = "probe-c-$run" ] \
     && [ "$(stored vr-4)" = "vr-4" ] && [ "$(stored vr-5)" = "vr-5" ]; then
    ok=1
    break
  fi
  sleep 2
  i=$((i + 1))
done
if [ -z "$ok" ]; then
  echo "After about 70 seconds the readings are not all processed: the shard is still stuck behind a bad record."
  exit 1
fi

Q="$(aws_local sqs get-queue-url --queue-name vitals-dead-letters --query QueueUrl --output text)"
kept=""
i=0
while [ "$i" -lt 12 ]; do
  msgs="$(aws_local sqs receive-message --queue-url "$Q" --max-number-of-messages 10 --visibility-timeout 0 \
    --wait-time-seconds 2 --query 'Messages[].Body' --output json 2>/dev/null || echo null)"
  if printf '%s' "$msgs" | jq -e --argjson s "$bad_seq" \
      'select(. != null) | any(.[]; (fromjson | .KinesisBatchInfo) as $b | ($b.startSequenceNumber|tonumber) <= $s and ($b.endSequenceNumber|tonumber) >= $s)' >/dev/null 2>&1; then
    kept=1
    break
  fi
  i=$((i + 1))
done
if [ -z "$kept" ]; then
  echo "The good readings flow, but the broken reading never arrived in vitals-dead-letters."
  exit 1
fi

echo "The bad reading was isolated and kept in vitals-dead-letters; every valid reading around it was processed."
