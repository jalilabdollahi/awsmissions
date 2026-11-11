#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local sqs create-queue --queue-name ironwood-ledger-events.fifo \
  --attributes FifoQueue=true,ContentBasedDeduplication=true
