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

src="$(aws_local sqs get-queue-url --queue-name ledgerlink-settlements --query QueueUrl --output text 2>/dev/null || true)"
if [ -z "$src" ]; then
  echo "ledgerlink-settlements no longer exists. Configure it, do not replace it."
  exit 1
fi

policy="$(aws_local sqs get-queue-attributes --queue-url "$src" --attribute-names RedrivePolicy \
  --query 'Attributes.RedrivePolicy' --output text 2>/dev/null || true)"
if [ -z "$policy" ] || [ "$policy" = "None" ]; then
  echo "ledgerlink-settlements has no redrive policy: a failing message will be retried forever and block the line."
  exit 1
fi

parsed="$(printf '%s' "$policy" | python3 -c '
import json, sys
p = json.load(sys.stdin)
print(p.get("deadLetterTargetArn", ""), p.get("maxReceiveCount", ""))')"
dlq_arn="${parsed% *}"
max_rc="${parsed##* }"
dlq_name="${dlq_arn##*:}"
if ! dlq="$(aws_local sqs get-queue-url --queue-name "$dlq_name" --query QueueUrl --output text 2>/dev/null)"; then
  echo "The redrive policy points at $dlq_arn, but no such queue exists."
  exit 1
fi
if [ "$dlq" = "$src" ]; then
  echo "A queue can not be its own dead-letter queue."
  exit 1
fi
if [ "$max_rc" -lt 2 ] || [ "$max_rc" -gt 10 ]; then
  echo "maxReceiveCount is $max_rc. Use between 2 and 10 so transient errors get a retry but a poison message is parked quickly."
  exit 1
fi

# Behaviour: a message that is received but never deleted must end up in the DLQ.
probe="$(make_probe "$policy")"
trap 'aws_local sqs delete-queue --queue-url "$probe" >/dev/null 2>&1 || true' EXIT
poison="malformed-settlement-$(date +%s)-$$"
aws_local sqs send-message --queue-url "$probe" --message-body "$poison" >/dev/null
i=0
while [ "$i" -le "$max_rc" ]; do
  aws_local sqs receive-message --queue-url "$probe" --query 'Messages[0].Body' --output text >/dev/null 2>&1 || true
  sleep 1.3
  i=$((i + 1))
done

parked="$(aws_local sqs receive-message --queue-url "$dlq" --max-number-of-messages 10 --visibility-timeout 0 \
  --query 'Messages[].Body' --output text 2>/dev/null | tr '\t' '\n' || true)"
if ! printf '%s\n' "$parked" | grep -qx "$poison"; then
  echo "A message was received $max_rc times without being deleted, but it never showed up in $dlq_name."
  exit 1
fi

keep="$(aws_local sqs get-queue-attributes --queue-url "$dlq" --attribute-names MessageRetentionPeriod \
  --query 'Attributes.MessageRetentionPeriod' --output text)"
if [ "$keep" != "1209600" ]; then
  echo "Parking works, but $dlq_name keeps messages for $((keep / 86400)) days. Retention on a DLQ should be the 14-day maximum so evidence outlives the source queue's retention."
  exit 1
fi

echo "Poison messages are now parked in $dlq_name after $max_rc attempts and kept for 14 days."
