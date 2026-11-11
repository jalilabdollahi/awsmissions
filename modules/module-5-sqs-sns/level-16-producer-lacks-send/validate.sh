#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

intake="$(aws_local sqs get-queue-url --queue-name gatehouse-intake --query QueueUrl --output text 2>/dev/null || true)"
audit="$(aws_local sqs get-queue-url --queue-name gatehouse-audit --query QueueUrl --output text 2>/dev/null || true)"
if [ -z "$intake" ] || [ -z "$audit" ]; then
  echo "gatehouse-intake and gatehouse-audit must both exist. Fix the user's policy, not the queues."
  exit 1
fi
if ! aws_local iam get-user --user-name gatehouse-api >/dev/null 2>&1; then
  echo "The IAM user gatehouse-api no longer exists."
  exit 1
fi

visitor="visitor-$(date +%s)-$$"
set +e
out="$(aws_as_user gatehouse-api sqs send-message --queue-url "$intake" --message-body "$visitor" 2>&1)"
rc=$?
set -e
if [ "$rc" -ne 0 ]; then
  echo "gatehouse-api still cannot send to gatehouse-intake: $(printf '%s' "$out" | tail -1)"
  exit 1
fi

# The message really arrived.
seen() {
  aws_local sqs receive-message --queue-url "$intake" --max-number-of-messages 10 --visibility-timeout 0 \
    --query 'Messages[].Body' --output text 2>/dev/null | grep -q "$visitor"
}
if ! wait_for "visitor message" 5 seen; then
  echo "The send was accepted but the registration is not in gatehouse-intake."
  exit 1
fi

if aws_as_user gatehouse-api sqs send-message --queue-url "$audit" --message-body "tamper-$visitor" >/dev/null 2>&1; then
  echo "gatehouse-api can now also write to gatehouse-audit. Scope the permission to the intake queue's ARN only."
  exit 1
fi
if aws_as_user gatehouse-api sqs receive-message --queue-url "$intake" >/dev/null 2>&1; then
  echo "gatehouse-api can read registrations back out of gatehouse-intake. A producer needs sqs:SendMessage, not receive or delete rights."
  exit 1
fi
if aws_as_user gatehouse-api sqs purge-queue --queue-url "$intake" >/dev/null 2>&1; then
  echo "gatehouse-api is allowed to purge gatehouse-intake. Remove broad actions like sqs:*."
  exit 1
fi

echo "gatehouse-api can send to gatehouse-intake and do nothing else. Registrations flow again."
