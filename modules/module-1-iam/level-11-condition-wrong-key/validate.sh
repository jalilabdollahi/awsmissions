#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

eu_url="$(aws_local --region eu-west-1 sqs get-queue-url --queue-name patient-events-eu --query QueueUrl --output text 2>/dev/null || true)"
us_url="$(aws_local --region us-east-1 sqs get-queue-url --queue-name patient-events-us --query QueueUrl --output text 2>/dev/null || true)"
if [ -z "$eu_url" ] || [ -z "$us_url" ]; then
  echo "A queue is missing (patient-events-eu / patient-events-us). The queues are fine, leave them."
  exit 1
fi

worker() { aws_as_user meridian-eu-worker "$@"; }

stamp="evt-$(date +%s)"
if ! out="$(worker --region eu-west-1 sqs send-message --queue-url "$eu_url" --message-body "$stamp" 2>&1)"; then
  echo "meridian-eu-worker cannot send to the eu-west-1 queue: $(printf '%s' "$out" | tail -1)"
  echo "The policy only applies when its Condition matches the request. Does the key in the Condition mean what the author thinks?"
  exit 1
fi
body="$(worker --region eu-west-1 sqs receive-message --queue-url "$eu_url" --visibility-timeout 0 \
  --query 'Messages[0].Body' --output text 2>&1 || true)"
if [ -z "$body" ] || [ "$body" = "None" ] || printf '%s' "$body" | grep -q 'rror'; then
  echo "Sending works but receiving from the eu-west-1 queue does not: $body"
  exit 1
fi

# The guardrail must survive: the same worker is refused outside the EU.
if worker --region us-east-1 sqs send-message --queue-url "$us_url" --message-body "leak-$stamp" >/dev/null 2>&1; then
  echo "meridian-eu-worker can use SQS in us-east-1. The data residency guardrail was lost; the Condition must still restrict the region."
  exit 1
fi

echo "meridian-eu-worker works in eu-west-1 and is still refused in us-east-1."
