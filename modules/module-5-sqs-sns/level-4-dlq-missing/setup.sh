#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# Short visibility timeout so a failing worker retries quickly.
aws_local sqs create-queue --queue-name ledgerlink-settlements \
  --attributes VisibilityTimeout=1 >/dev/null

echo "ledgerlink-settlements has no dead-letter queue. The poison pill will loop forever."
