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

out="$(aws_local sqs get-queue-url --queue-name mailroom-outbound --query QueueUrl --output text 2>/dev/null || true)"
dlq="$(aws_local sqs get-queue-url --queue-name mailroom-outbound-dlq --query QueueUrl --output text 2>/dev/null || true)"
if [ -z "$out" ] || [ -z "$dlq" ]; then
  echo "Both mailroom-outbound and mailroom-outbound-dlq must exist. Repair the link between them."
  exit 1
fi

parked_before="$(aws_local sqs get-queue-attributes --queue-url "$dlq" --attribute-names ApproximateNumberOfMessages \
  --query 'Attributes.ApproximateNumberOfMessages' --output text)"
if [ "$parked_before" -lt 2 ]; then
  echo "The two jobs that were already parked in mailroom-outbound-dlq are gone. Do not purge or recreate the DLQ."
  exit 1
fi

policy="$(aws_local sqs get-queue-attributes --queue-url "$out" --attribute-names RedrivePolicy \
  --query 'Attributes.RedrivePolicy' --output text 2>/dev/null || true)"
if [ -z "$policy" ] || [ "$policy" = "None" ]; then
  echo "mailroom-outbound has lost its redrive policy entirely. It must keep one that points at a real DLQ."
  exit 1
fi
max_rc="$(printf '%s' "$policy" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("maxReceiveCount",""))')"
if [ "$max_rc" -gt 5 ]; then
  echo "maxReceiveCount is $max_rc. Bounced mails should be parked after at most 5 attempts."
  exit 1
fi

# Behaviour: fail a job on purpose and see where it goes.
probe="$(make_probe "$policy")"
trap 'aws_local sqs delete-queue --queue-url "$probe" >/dev/null 2>&1 || true' EXIT
job="{\"to\":\"nobody-$(date +%s)@example.test\",\"status\":\"probe\"}"
aws_local sqs send-message --queue-url "$probe" --message-body "$job" >/dev/null
i=0
while [ "$i" -le "$max_rc" ]; do
  aws_local sqs receive-message --queue-url "$probe" --query 'Messages[0].Body' --output text >/dev/null 2>&1 || true
  sleep 1.3
  i=$((i + 1))
done

found="$(aws_local sqs receive-message --queue-url "$dlq" --max-number-of-messages 10 --visibility-timeout 0 \
  --query 'Messages[].Body' --output text 2>/dev/null | tr '\t' '\n' | grep -cxF "$job" || true)"
if [ "$found" -lt 1 ]; then
  echo "A job failed $max_rc times and was dropped: it is not in mailroom-outbound-dlq. Compare the redrive policy's target with the queue that really exists."
  exit 1
fi

echo "Failed jobs from mailroom-outbound now land in mailroom-outbound-dlq, and the old parked jobs are intact."
