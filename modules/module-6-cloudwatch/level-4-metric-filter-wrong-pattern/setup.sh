#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local logs create-log-group --log-group-name /ledgerbox/payments
aws_local logs create-log-stream --log-group-name /ledgerbox/payments --log-stream-name gateway-1

# The filter exactly as written in the player's workspace/filter.json.
aws_local logs put-metric-filter --cli-input-json "file://$MISSION_DIR/workspace/filter.json"

echo "payment-failures is installed, yet Ledgerbox/PaymentFailures never moves."
