#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

if ! url="$(aws_local sqs get-queue-url --queue-name labelforge-jobs --query QueueUrl --output text 2>/dev/null)"; then
  echo "The queue labelforge-jobs is gone. Fix its settings instead of replacing it."
  exit 1
fi

# Take a job the way a worker does, then keep it "rendering" for 9 seconds
# (longer than the slowest label) without deleting it.
claim=""
for _ in 1 2 3 4 5 6 7 8; do
  claim="$(aws_local sqs receive-message --queue-url "$url" \
    --query 'Messages[0].[MessageId,ReceiptHandle]' --output text 2>/dev/null || true)"
  [ -n "$claim" ] && [ "$claim" != "None" ] && break
  sleep 2
done
if [ -z "$claim" ] || [ "$claim" = "None" ]; then
  echo "No job could be received from labelforge-jobs. Leave the jobs that are waiting in the queue; do not purge it."
  exit 1
fi
first_id="$(printf '%s' "$claim" | awk '{print $1}')"
receipt="$(printf '%s' "$claim" | awk '{print $2}')"
# Hand the job back whatever happens, so the queue is left as we found it.
trap 'aws_local sqs change-message-visibility --queue-url "$url" --receipt-handle "$receipt" --visibility-timeout 0 >/dev/null 2>&1 || true' EXIT
sleep 9

again="$(aws_local sqs receive-message --queue-url "$url" --max-number-of-messages 10 --visibility-timeout 0 \
  --query 'Messages[].MessageId' --output text 2>/dev/null | tr '\t' '\n' || true)"
if printf '%s\n' "$again" | grep -qx "$first_id"; then
  echo "A job was handed to a second worker 9 seconds after the first one took it, while a label can still be rendering. A worker's claim on a message expires too early."
  exit 1
fi

vt="$(aws_local sqs get-queue-attributes --queue-url "$url" --attribute-names VisibilityTimeout \
  --query 'Attributes.VisibilityTimeout' --output text)"
if [ "$vt" -gt 120 ]; then
  echo "Duplicates are gone, but a crashed worker would now keep a job invisible for ${vt}s. Jobs must be retried within 2 minutes (120s)."
  exit 1
fi

echo "A claimed job stays hidden for the whole rendering time and still returns within 2 minutes if a worker dies. No more double labels."
