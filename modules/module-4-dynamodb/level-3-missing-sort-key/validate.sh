#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

T=fixline-ticket-events
if ! aws_local dynamodb describe-table --table-name "$T" >/dev/null 2>&1; then
  echo "$T does not exist. The service needs it back under the same name."
  exit 1
fi

# Replay one ticket's life: three events must survive as three items.
for e in "opened|2026-04-01T08:00:00Z" "assigned|2026-04-01T08:30:00Z" "resolved|2026-04-01T12:00:00Z"; do
  kind="${e%%|*}"; at="${e##*|}"
  if ! out="$(aws_local dynamodb put-item --table-name "$T" \
      --item "{\"ticketId\":{\"S\":\"T-check\"},\"eventAt\":{\"S\":\"$at\"},\"kind\":{\"S\":\"$kind\"}}" 2>&1)"; then
    echo "A ticket event could not be written: $(printf '%s' "$out" | tail -1)"
    exit 1
  fi
done

count="$(aws_local dynamodb query --table-name "$T" \
  --key-condition-expression 'ticketId = :t' \
  --expression-attribute-values '{":t":{"S":"T-check"}}' \
  --select COUNT --query Count --output text 2>&1 || true)"
if [ "$count" != "3" ]; then
  echo "Three events were written for T-check but a query returns $count item(s). Events of the same ticket are still overwriting each other."
  exit 1
fi

if ! window="$(aws_local dynamodb query --table-name "$T" \
    --key-condition-expression 'ticketId = :t AND eventAt >= :since' \
    --expression-attribute-values '{":t":{"S":"T-check"},":since":{"S":"2026-04-01T08:15:00Z"}}' \
    --query 'Items[].kind.S' --output text 2>&1)"; then
  echo "The time-window read failed: $(printf '%s' "$window" | tail -1)"
  exit 1
fi
if [ "$window" != "$(printf 'assigned\tresolved')" ]; then
  echo "Window query since 08:15 returned [$window], expected [assigned resolved] in time order."
  exit 1
fi

bad="$(aws_local dynamodb describe-table --table-name "$T" \
  --query 'Table.KeySchema[?AttributeName==`ticketId`].KeyType' --output text)"
if [ "$bad" != "HASH" ]; then
  echo "ticketId should remain the partition key so one ticket's events live together."
  exit 1
fi

for at in 2026-04-01T08:00:00Z 2026-04-01T08:30:00Z 2026-04-01T12:00:00Z; do
  aws_local dynamodb delete-item --table-name "$T" --key "{\"ticketId\":{\"S\":\"T-check\"},\"eventAt\":{\"S\":\"$at\"}}" >/dev/null
done
echo "Ticket history is kept event by event and can be read by time window."
