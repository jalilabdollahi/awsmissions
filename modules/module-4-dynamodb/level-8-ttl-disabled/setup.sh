#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local dynamodb create-table --table-name loginly-sessions \
  --attribute-definitions AttributeName=sessionId,AttributeType=S \
  --key-schema AttributeName=sessionId,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST >/dev/null

# "We turned on TTL" - but on an attribute no item has.
aws_local dynamodb update-time-to-live --table-name loginly-sessions \
  --time-to-live-specification Enabled=true,AttributeName=expires >/dev/null

now="$(date +%s)"
aws_local dynamodb put-item --table-name loginly-sessions \
  --item "{\"sessionId\":{\"S\":\"sess-last-year\"},\"userId\":{\"S\":\"u-88\"},\"expiresAt\":{\"N\":\"$((now - 31536000))\"}}"
aws_local dynamodb put-item --table-name loginly-sessions \
  --item "{\"sessionId\":{\"S\":\"sess-live\"},\"userId\":{\"S\":\"u-12\"},\"expiresAt\":{\"N\":\"$((now + 86400))\"}}"

echo "loginly-sessions has TTL enabled. Sessions from last year are still in there."
