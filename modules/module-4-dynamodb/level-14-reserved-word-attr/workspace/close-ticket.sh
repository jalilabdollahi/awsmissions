#!/usr/bin/env bash
# Usage: ./close-ticket.sh tk-77 "note for the customer"
ENDPOINT="${AWS_ENDPOINT_URL:-http://localhost:4566}"
ID="${1:?ticket id}"
NOTE="${2:?closing note}"

aws --endpoint-url "$ENDPOINT" dynamodb update-item \
  --table-name deskly-tickets \
  --key "{\"ticketId\":{\"S\":\"$ID\"}}" \
  --update-expression "SET status = :closed, comment = :note, timestamp = :now" \
  --expression-attribute-values "{\":closed\":{\"S\":\"CLOSED\"},\":note\":{\"S\":\"$NOTE\"},\":now\":{\"N\":\"$(date +%s)\"}}"
