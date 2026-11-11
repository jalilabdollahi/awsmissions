#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

if ! url="$(aws_local sqs get-queue-url --queue-name tidewater-payments.fifo --query QueueUrl --output text 2>/dev/null)"; then
  echo "tidewater-payments.fifo is gone. Reconfigure it instead of deleting it."
  exit 1
fi

waiting="$(aws_local sqs get-queue-attributes --queue-url "$url" --attribute-names ApproximateNumberOfMessages \
  --query 'Attributes.ApproximateNumberOfMessages' --output text)"
if [ "$waiting" -lt 1 ]; then
  echo "The capture job for pay_000001 that was waiting in the queue is gone. The queue must be changed in place, not recreated."
  exit 1
fi

# The webhook receiver's behaviour: same body, no dedup id, sent twice.
errf="$(mktemp)"
cb="{\"capture\":\"pay_$(date +%s)$$\",\"amount\":4200}"
if ! aws_local sqs send-message --queue-url "$url" --message-group-id merchant-9 --message-body "$cb" >/dev/null 2>"$errf"; then
  echo "A callback without MessageDeduplicationId is rejected: $(tail -1 "$errf")"
  rm -f "$errf"
  exit 1
fi
rm -f "$errf"
aws_local sqs send-message --queue-url "$url" --message-group-id merchant-9 --message-body "$cb" >/dev/null

# Read everything back without consuming it and count the copies of our callback.
copies=0
tries=0
while [ "$tries" -lt 4 ]; do
  batch="$(aws_local sqs receive-message --queue-url "$url" --max-number-of-messages 10 --visibility-timeout 0 \
    --query 'Messages[].Body' --output text 2>/dev/null | tr '\t' '\n' || true)"
  copies="$(printf '%s\n' "$batch" | grep -cxF "$cb" || true)"
  [ "$copies" -gt 0 ] && break
  tries=$((tries + 1))
done

if [ "$copies" -ne 1 ]; then
  echo "The gateway re-delivered the same callback and the queue now holds $copies copies of it. Duplicates inside the deduplication window must be dropped."
  exit 1
fi

echo "Callbacks without ids are accepted, and a re-delivered callback is enqueued only once. The waiting capture job survived."
