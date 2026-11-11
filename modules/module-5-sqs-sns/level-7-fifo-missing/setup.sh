#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

old="$(aws_local sqs create-queue --queue-name ironwood-ledger-events --query QueueUrl --output text)"
aws_local sqs send-message --queue-url "$old" \
  --message-body '{"account":"acct-17","type":"deposit","cents":50000}' >/dev/null

echo "ironwood-ledger-events is a standard queue: best-effort ordering only."
