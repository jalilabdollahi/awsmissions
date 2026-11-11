#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local dynamodb update-table --table-name postbox-prefs --no-deletion-protection-enabled >/dev/null
aws_local dynamodb delete-table --table-name postbox-prefs >/dev/null
aws_local dynamodb create-table --table-name postbox-prefs \
  --attribute-definitions AttributeName=recipientId,AttributeType=S \
  --key-schema AttributeName=recipientId,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --deletion-protection-enabled
