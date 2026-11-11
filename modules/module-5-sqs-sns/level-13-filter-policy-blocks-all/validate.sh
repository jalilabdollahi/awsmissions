#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

topic_arn="arn:aws:sns:us-east-1:${ACCOUNT_ID}:cobalt-order-events"
queue="$(aws_local sqs get-queue-url --queue-name cobalt-refund-worker --query QueueUrl --output text 2>/dev/null || true)"
if [ -z "$queue" ]; then
  echo "The queue cobalt-refund-worker is gone."
  exit 1
fi

# Publish three events the way the vendor product does: JSON body, no message attributes.
run="$(date +%s)$$"
for kind in order_created order_cancelled order_refunded; do
  aws_local sns publish --topic-arn "$topic_arn" \
    --message "{\"eventType\":\"$kind\",\"orderId\":\"o-$run-$kind\"}" >/dev/null
done

collect() {
  aws_local sqs receive-message --queue-url "$queue" --max-number-of-messages 10 --visibility-timeout 0 \
    --query 'Messages[].Body' --output text 2>/dev/null | grep -o "o-$run-[a-z_]*" | sort -u | tr '\n' ' ' || true
}
enough() { [ "$(collect | wc -w | tr -d ' ')" -ge 2 ]; }

if ! wait_for "filtered delivery" 8 enough; then
  echo "Cancellation and refund events never reached cobalt-refund-worker. The filter matches on eventType, but SNS looks for that name somewhere other than where the publisher puts it."
  exit 1
fi
sleep 1
got="$(collect)"
case " $got " in
  *" o-$run-order_created "*)
    echo "order_created events are reaching the refund worker. The subscription must still filter on eventType (only order_cancelled and order_refunded)."
    exit 1 ;;
esac
case "$got" in
  *"o-$run-order_cancelled"*) have_cancel=1 ;;
  *) have_cancel=0 ;;
esac
case "$got" in
  *"o-$run-order_refunded"*) have_refund=1 ;;
  *) have_refund=0 ;;
esac
if [ "$have_cancel" -eq 1 ] && [ "$have_refund" -eq 1 ]; then
  echo "The refund worker now receives cancellations and refunds, and nothing else."
else
  echo "Only part of the wanted events arrived (got: $got). Both order_cancelled and order_refunded must reach the worker."
  exit 1
fi
