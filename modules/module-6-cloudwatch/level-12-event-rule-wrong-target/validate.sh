#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

prod="$(aws_local sqs get-queue-url --queue-name harbor-ingest-prod --query QueueUrl --output text 2>/dev/null || true)"
stage="$(aws_local sqs get-queue-url --queue-name harbor-ingest-staging --query QueueUrl --output text 2>/dev/null || true)"
if [ -z "$prod" ] || [ -z "$stage" ]; then
  echo "harbor-ingest-prod and harbor-ingest-staging must both exist; the problem is the rule's target."
  exit 1
fi

booking="BK-$(date +%s)-$$"
aws_local events put-events --entries \
  "[{\"Source\":\"harbor.bookings\",\"DetailType\":\"ShipmentCreated\",\"Detail\":\"{\\\"booking\\\":\\\"$booking\\\"}\"}]" >/dev/null

holds() {
  aws_local sqs receive-message --queue-url "$1" --max-number-of-messages 10 --visibility-timeout 0 \
    --query 'Messages[].Body' --output text 2>/dev/null | grep -q "$booking"
}
if ! wait_for "booking in prod" 10 holds "$prod"; then
  echo "The booking $booking never arrived in harbor-ingest-prod. List the rule's targets and read where each one points."
  exit 1
fi
sleep 1
if holds "$stage"; then
  echo "The booking is also being copied to harbor-ingest-staging. Remove the staging target; production events must not reach staging."
  exit 1
fi

echo "ShipmentCreated events go to harbor-ingest-prod only."
