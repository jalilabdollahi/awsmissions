#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local sqs create-queue --queue-name gold-concierge >/dev/null
aws_local events put-rule --name quillshop-gold-orders --state ENABLED \
  --event-pattern "file://$MISSION_DIR/workspace/pattern.json" >/dev/null
aws_local events put-targets --rule quillshop-gold-orders \
  --targets "Id=concierge,Arn=arn:aws:sqs:us-east-1:${ACCOUNT_ID}:gold-concierge" >/dev/null

echo "quillshop-gold-orders is enabled and targeted. Its pattern matches nothing the shop publishes."
