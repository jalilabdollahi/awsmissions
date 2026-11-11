#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# Clone the queue's current redrive settings onto a throwaway queue and test
# that one, so every check starts from a clean slate.
make_probe() {
  local attrs
  attrs="$(mktemp)"
  POLICY="$1" python3 -c '
import json, os
print(json.dumps({"VisibilityTimeout": "1", "RedrivePolicy": os.environ["POLICY"]}))' > "$attrs"
  aws_local sqs create-queue --queue-name "awsm-probe-$$" --attributes "file://$attrs" \
    --query QueueUrl --output text
  rm -f "$attrs"
}

sms="$(aws_local sqs get-queue-url --queue-name pinecrest-sms --query QueueUrl --output text 2>/dev/null || true)"
dlq="$(aws_local sqs get-queue-url --queue-name pinecrest-sms-dlq --query QueueUrl --output text 2>/dev/null || true)"
if [ -z "$sms" ] || [ -z "$dlq" ]; then
  echo "pinecrest-sms and pinecrest-sms-dlq must both exist."
  exit 1
fi

policy="$(aws_local sqs get-queue-attributes --queue-url "$sms" --attribute-names RedrivePolicy \
  --query 'Attributes.RedrivePolicy' --output text 2>/dev/null || true)"
if [ -z "$policy" ] || [ "$policy" = "None" ]; then
  echo "pinecrest-sms has no redrive policy any more. It must keep dead-lettering failed messages."
  exit 1
fi
target="$(printf '%s' "$policy" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("deadLetterTargetArn",""))')"
if [ "${target##*:}" != "pinecrest-sms-dlq" ]; then
  echo "The redrive policy no longer points at pinecrest-sms-dlq."
  exit 1
fi
probe="$(make_probe "$policy")"
trap 'aws_local sqs delete-queue --queue-url "$probe" >/dev/null 2>&1 || true' EXIT

# One reminder, two simulated provider failures (received, never deleted).
reminder="reminder-$(date +%s)-$$"
aws_local sqs send-message --queue-url "$probe" --message-body "$reminder" >/dev/null

attempt=1
while [ "$attempt" -le 3 ]; do
  got="$(aws_local sqs receive-message --queue-url "$probe" \
    --query 'Messages[0].[Body,ReceiptHandle]' --output text 2>/dev/null || true)"
  if [ "$(printf '%s' "$got" | awk '{print $1}')" != "$reminder" ]; then
    echo "The reminder was parked in the DLQ before attempt $attempt. It must survive two failed attempts and still be deliverable on the third."
    exit 1
  fi
  if [ "$attempt" -lt 3 ]; then
    sleep 1.3
  else
    # The third delivery succeeds: acknowledge it.
    aws_local sqs delete-message --queue-url "$probe" --receipt-handle "$(printf '%s' "$got" | awk '{print $2}')" >/dev/null
  fi
  attempt=$((attempt + 1))
done

# Now a message that never succeeds must still be parked in time.
poison="poison-$(date +%s)-$$"
aws_local sqs send-message --queue-url "$probe" --message-body "$poison" >/dev/null
tries=0
while [ "$tries" -lt 11 ]; do
  aws_local sqs receive-message --queue-url "$probe" --visibility-timeout 1 --query 'Messages[0].Body' --output text >/dev/null 2>&1 || true
  sleep 1.2
  parked="$(aws_local sqs receive-message --queue-url "$dlq" --max-number-of-messages 10 --visibility-timeout 0 \
    --query 'Messages[].Body' --output text 2>/dev/null | tr '\t' '\n' | grep -cxF "$poison" || true)"
  if [ "$parked" -ge 1 ]; then
    echo "A reminder survives two failed attempts, and a message that never succeeds is still parked in pinecrest-sms-dlq (after $((tries + 1)) attempts)."
    exit 0
  fi
  tries=$((tries + 1))
done
echo "A message that never succeeds was received 11 times and is still not in the DLQ. maxReceiveCount is too generous: poison messages must be parked after at most 10 attempts."
exit 1
