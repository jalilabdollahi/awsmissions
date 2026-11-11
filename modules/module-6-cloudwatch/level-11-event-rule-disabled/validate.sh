#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

queue="$(aws_local sqs get-queue-url --queue-name skyline-receipts --query QueueUrl --output text 2>/dev/null || true)"
if [ -z "$queue" ]; then
  echo "The queue skyline-receipts is gone."
  exit 1
fi
if ! aws_local events describe-rule --name skyline-ticket-sold >/dev/null 2>&1; then
  echo "The rule skyline-ticket-sold no longer exists. Repair it instead of removing it."
  exit 1
fi

ticket="T-$(date +%s)-$$"
publish() {
  aws_local events put-events --entries \
    "[{\"Source\":\"skyline.box-office\",\"DetailType\":\"$1\",\"Detail\":\"{\\\"ticket\\\":\\\"$2\\\"}\"}]" >/dev/null
}
publish TicketSold "$ticket"
publish TicketRefunded "refund-$ticket"

got() {
  aws_local sqs receive-message --queue-url "$queue" --max-number-of-messages 10 --visibility-timeout 0 \
    --query 'Messages[].Body' --output text 2>/dev/null
}
for _ in $(seq 1 10); do
  got | grep -q "\"$ticket\"" && break
  sleep 1
done
all="$(got)"
if ! printf '%s' "$all" | grep -q "\"$ticket\""; then
  state="$(aws_local events describe-rule --name skyline-ticket-sold --query State --output text)"
  echo "The TicketSold event never reached skyline-receipts. The rule's state is $state."
  exit 1
fi
if printf '%s' "$all" | grep -q "refund-$ticket"; then
  echo "A TicketRefunded event was forwarded too. The rule must stay selective: only TicketSold events."
  exit 1
fi

echo "Sold tickets flow into skyline-receipts again, and refunds stay out."
