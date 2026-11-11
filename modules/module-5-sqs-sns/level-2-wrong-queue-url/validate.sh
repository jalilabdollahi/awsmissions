#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

prod_url="$(aws_local sqs get-queue-url --queue-name ticketdesk-support --query QueueUrl --output text 2>/dev/null || true)"
staging_url="$(aws_local sqs get-queue-url --queue-name ticketdesk-support-staging --query QueueUrl --output text 2>/dev/null || true)"
if [ -z "$prod_url" ] || [ -z "$staging_url" ]; then
  echo "Both ticketdesk-support and ticketdesk-support-staging must still exist. Fix the parameter, not the queues."
  exit 1
fi

# Act like the API: resolve the destination from the parameter, then send.
configured="$(aws_local ssm get-parameter --name /ticketdesk/prod/support-queue-url \
  --query Parameter.Value --output text 2>/dev/null || true)"
if [ -z "$configured" ]; then
  echo "The parameter /ticketdesk/prod/support-queue-url is gone; the API has no destination."
  exit 1
fi

ticket="ticket-$(date +%s)-$$"
if ! aws_local sqs send-message --queue-url "$configured" --message-body "$ticket" >/dev/null 2>&1; then
  echo "The API cannot send to the value stored in the parameter ($configured): SQS rejects it."
  exit 1
fi

seen_in() {
  aws_local sqs receive-message --queue-url "$1" --max-number-of-messages 10 --visibility-timeout 0 \
    --query 'Messages[].Body' --output text 2>/dev/null | tr '\t' '\n' | grep -qx "$ticket"
}

if seen_in "$staging_url"; then
  echo "A production ticket just landed in ticketdesk-support-staging. The parameter still points at the staging queue."
  exit 1
fi
if ! seen_in "$prod_url"; then
  echo "The ticket was accepted but did not arrive in ticketdesk-support."
  exit 1
fi

echo "Production tickets now land in ticketdesk-support. The agents' worker is picking them up."
