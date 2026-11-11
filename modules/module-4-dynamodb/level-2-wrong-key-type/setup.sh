#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# Hand-made table: recipientId was declared as a Number, and deletion protection is on.
aws_local dynamodb create-table --table-name postbox-prefs \
  --attribute-definitions AttributeName=recipientId,AttributeType=N \
  --key-schema AttributeName=recipientId,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --deletion-protection-enabled >/dev/null

echo "postbox-prefs is deployed. The preferences service cannot write to it."
