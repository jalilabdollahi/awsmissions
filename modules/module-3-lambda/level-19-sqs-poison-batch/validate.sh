#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

FN=ticket-processor
Q="$(aws_local sqs get-queue-url --queue-name ticket-events --query QueueUrl --output text)"
DLQ="$(aws_local sqs get-queue-url --queue-name ticket-events-dlq --query QueueUrl --output text)"

esm="$(aws_local lambda list-event-source-mappings --function-name "$FN" --output json)"
if [ "$(printf '%s' "$esm" | jq '.EventSourceMappings | length')" = "0" ]; then
  echo "The queue is no longer connected to $FN. Fix the existing mapping instead of removing it."
  exit 1
fi
if ! printf '%s' "$esm" | jq -e '.EventSourceMappings[0].FunctionResponseTypes // [] | index("ReportBatchItemFailures") != null' >/dev/null; then
  echo "The event source mapping does not accept per-message failure reports from the function, so any failure still fails the whole batch."
  exit 1
fi

run="$(date +%s)"
good1="T-$run-1"; good2="T-$run-2"; good3="T-$run-3"
entries="$(jq -cn --arg a "$good1" --arg b "$good2" --arg c "$good3" '[
  {Id:"1",MessageBody:({ticket_id:$a}|tojson)},
  {Id:"2",MessageBody:"{this is not json"},
  {Id:"3",MessageBody:({ticket_id:$b}|tojson)},
  {Id:"4",MessageBody:({ticket_id:$c}|tojson)}]')"
aws_local sqs send-message-batch --queue-url "$Q" --entries "$entries" >/dev/null

# The poison message must travel the whole redrive path: 3 receives, then the DLQ.
found=""
i=0
while [ "$i" -lt 14 ]; do
  body="$(aws_local sqs receive-message --queue-url "$DLQ" --max-number-of-messages 10 --visibility-timeout 0 \
    --wait-time-seconds 3 --query 'Messages[].Body' --output json 2>/dev/null || echo null)"
  if printf '%s' "$body" | jq -e 'select(. != null) | any(. == "{this is not json")' >/dev/null 2>&1; then
    found=1
    break
  fi
  i=$((i + 1))
done

attempts() {
  aws_local dynamodb get-item --table-name ticket-ledger --key "{\"ticket_id\":{\"S\":\"$1\"}}" \
    --query 'Item.attempts.N' --output text 2>/dev/null || true
}
a1="$(attempts "$good1")"; a2="$(attempts "$good2")"; a3="$(attempts "$good3")"

if [ -z "$found" ]; then
  if [ "$a1$a2$a3" = "NoneNoneNone" ] || [ -z "$a1$a2$a3" ]; then
    echo "Nothing happened within ~60 seconds: the good events were not processed and the poison event never reached the DLQ."
  else
    echo "The malformed event never arrived in ticket-events-dlq. It was either swallowed (success reported for it) or is still being retried."
  fi
  exit 1
fi
for pair in "$good1:$a1" "$good2:$a2" "$good3:$a3"; do
  id="${pair%%:*}"; n="${pair##*:}"
  if [ "$n" != "1" ]; then
    echo "Ticket $id was processed '${n}' time(s), expected exactly once. A bad neighbour must not cause good events to be retried."
    exit 1
  fi
done

left="$(aws_local sqs receive-message --queue-url "$DLQ" --max-number-of-messages 10 --visibility-timeout 0 \
  --query 'Messages[].Body' --output json 2>/dev/null || echo null)"
if printf '%s' "$left" | jq -e --arg a "$good1" --arg b "$good2" --arg c "$good3" \
     'select(. != null) | any(contains($a) or contains($b) or contains($c))' >/dev/null 2>&1; then
  echo "A good ticket ended up in the dead-letter queue. Only the malformed event belongs there."
  exit 1
fi

echo "The batch was split correctly: 3 good tickets processed once each, the malformed event is in ticket-events-dlq."
