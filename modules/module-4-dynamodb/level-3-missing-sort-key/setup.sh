#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local dynamodb create-table --table-name fixline-ticket-events \
  --attribute-definitions AttributeName=ticketId,AttributeType=S \
  --key-schema AttributeName=ticketId,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST >/dev/null

# Each put replaced the previous event of the same ticket, so only the last one survives.
for e in "T-1001|opened|2026-03-02T08:05:00Z" "T-1001|assigned|2026-03-02T08:20:00Z" "T-1001|resolved|2026-03-02T10:45:00Z" \
         "T-1002|opened|2026-03-02T09:00:00Z" "T-1002|escalated|2026-03-02T09:40:00Z"; do
  tid="${e%%|*}"; rest="${e#*|}"; kind="${rest%%|*}"; at="${rest##*|}"
  aws_local dynamodb put-item --table-name fixline-ticket-events \
    --item "{\"ticketId\":{\"S\":\"$tid\"},\"eventAt\":{\"S\":\"$at\"},\"kind\":{\"S\":\"$kind\"}}"
done

echo "Fixline timelines are live. Every ticket shows exactly one event."
