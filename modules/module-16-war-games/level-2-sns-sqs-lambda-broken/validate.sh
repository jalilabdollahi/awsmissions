#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

TOPIC="arn:aws:sns:us-east-1:${ACCOUNT_ID}:tt-ticket-events"
QARN="arn:aws:sqs:us-east-1:${ACCOUNT_ID}:tt-ticket-fulfilment"
bad=0
echo "TT-5530 pipeline status"

for res in "sns get-topic-attributes --topic-arn $TOPIC" "sqs get-queue-url --queue-name tt-ticket-fulfilment" "lambda get-function --function-name tt-ticket-fulfiller" "dynamodb describe-table --table-name tt-fulfilled-tickets"; do
  # shellcheck disable=SC2086
  if ! aws_local $res >/dev/null 2>&1; then
    echo "A piece of the pipeline no longer exists (aws $res). Repair it, don't delete it."
    exit 1
  fi
done

# Stage 1: what does the subscription let through, and in which format?
sub="$(aws_local sns list-subscriptions-by-topic --topic-arn "$TOPIC" --query "Subscriptions[?Endpoint=='$QARN'].SubscriptionArn | [0]" --output text 2>/dev/null || true)"
if [ -z "$sub" ] || [ "$sub" = "None" ]; then
  echo "The queue is not subscribed to the topic at all."
  exit 1
fi
attrs="$(aws_local sns get-subscription-attributes --subscription-arn "$sub" --query Attributes --output json)"
filter="$(printf '%s' "$attrs" | jq -r '.FilterPolicy // empty')"
raw="$(printf '%s' "$attrs" | jq -r '.RawMessageDelivery // "false"')"

if [ -z "$filter" ]; then
  echo "[FAULT] stage 1  subscription accepts every event type - refunds would be fulfilled as sales"
  bad=$((bad + 1))
else
  sold="$(printf '%s' "$filter" | jq -r '[.eventType[]? | select(. == "TicketSold")] | length')"
  refund="$(printf '%s' "$filter" | jq -r '[.eventType[]? | select(. == "TicketRefunded")] | length')"
  if [ "$refund" != "0" ]; then
    echo "[FAULT] stage 1  subscription would let TicketRefunded through to fulfilment"
    bad=$((bad + 1))
  elif [ "$sold" = "0" ]; then
    echo "[FAULT] stage 1  TicketSold events are being filtered out before they reach the queue"
    bad=$((bad + 1))
  else
    echo "[ok]    stage 1  filter lets TicketSold in and keeps refunds out"
  fi
fi
if [ "$raw" != "true" ]; then
  echo "[FAULT] stage 1b messages that land in the queue do not have the shape the fulfiller expects"
  bad=$((bad + 1))
else
  echo "[ok]    stage 1b queue receives the checkout payload as-is"
fi

# Stage 2: is the mapping running?
state="$(aws_local lambda list-event-source-mappings --function-name tt-ticket-fulfiller \
  --query "EventSourceMappings[?EventSourceArn=='$QARN'].State | [0]" --output text 2>/dev/null || true)"
if [ "$state" = "Enabled" ]; then
  echo "[ok]    stage 2  queue -> function mapping is enabled"
else
  echo "[FAULT] stage 2  queue -> function mapping state is '${state:-missing}'"
  bad=$((bad + 1))
fi

# Stage 3: can the function actually run? Invoke it with a probe record.
rec='{"Records":[{"messageId":"m-probe","body":"{\"ticketId\":\"PROBE-0\",\"seat\":\"Z0\"}"}]}'
out="$(mktemp)"
aws_local lambda invoke --function-name tt-ticket-fulfiller --cli-binary-format raw-in-base64-out \
  --payload "$rec" "$out" >/dev/null 2>"$out.err" || true
if grep -qi 'TooManyRequests\|Rate Exceeded' "$out.err"; then
  echo "[FAULT] stage 3  invoking tt-ticket-fulfiller is rejected with a throttling error"
  bad=$((bad + 1))
elif [ "$(aws_local dynamodb get-item --table-name tt-fulfilled-tickets --key '{"ticketId":{"S":"PROBE-0"}}' --query Item.seat.S --output text 2>/dev/null)" = "Z0" ]; then
  echo "[ok]    stage 3  function runs and writes to the table"
  aws_local dynamodb delete-item --table-name tt-fulfilled-tickets --key '{"ticketId":{"S":"PROBE-0"}}' >/dev/null
else
  echo "[FAULT] stage 3  function ran but did not write the probe ticket: $(head -c 200 "$out.err")"
  bad=$((bad + 1))
fi
rm -f "$out" "$out.err"

if [ "$bad" -gt 0 ]; then
  echo "$bad stage(s) still broken - not sending a live order through yet."
  exit 1
fi

# End to end: one sale and one refund through the real topic.
id="T-$(date +%s)"
aws_local sns publish --topic-arn "$TOPIC" --message "{\"ticketId\":\"$id\",\"seat\":\"B7\"}" \
  --message-attributes '{"eventType":{"DataType":"String","StringValue":"TicketSold"}}' >/dev/null
aws_local sns publish --topic-arn "$TOPIC" --message "{\"ticketId\":\"R-$id\",\"seat\":\"B8\"}" \
  --message-attributes '{"eventType":{"DataType":"String","StringValue":"TicketRefunded"}}' >/dev/null
landed() { [ "$(aws_local dynamodb get-item --table-name tt-fulfilled-tickets --key "{\"ticketId\":{\"S\":\"$id\"}}" --query Item.seat.S --output text 2>/dev/null)" = "B7" ]; }
if ! wait_for "sold ticket in tt-fulfilled-tickets" 60 landed; then
  echo "A TicketSold event was published but no item appeared within 60s. Look at what each stage did with it."
  exit 1
fi
if [ "$(aws_local dynamodb get-item --table-name tt-fulfilled-tickets --key "{\"ticketId\":{\"S\":\"R-$id\"}}" --query Item.seat.S --output text 2>/dev/null)" = "B8" ]; then
  echo "The refund event was fulfilled as a sale. Filtering must stay in place."
  exit 1
fi
echo "A live TicketSold event travelled topic -> queue -> function -> table, and the refund stayed out. Fulfilment is back."
