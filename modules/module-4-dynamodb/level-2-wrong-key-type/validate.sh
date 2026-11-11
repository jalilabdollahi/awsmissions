#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

rider="7f3c2a9e-1b64-4d0a-9c1e-5a2b8d4e6f10"

if ! aws_local dynamodb describe-table --table-name postbox-prefs >/dev/null 2>&1; then
  echo "postbox-prefs does not exist right now. The service still expects a table with that exact name."
  exit 1
fi

if ! out="$(aws_local dynamodb put-item --table-name postbox-prefs \
    --item "{\"recipientId\":{\"S\":\"$rider\"},\"push\":{\"BOOL\":true},\"quietHours\":{\"S\":\"22:00-07:00\"}}" 2>&1)"; then
  echo "Writing a preference item for a UUID rider still fails:"
  echo "  $(printf '%s' "$out" | tail -1)"
  exit 1
fi

got="$(aws_local dynamodb get-item --table-name postbox-prefs \
  --key "{\"recipientId\":{\"S\":\"$rider\"}}" --query 'Item.quietHours.S' --output text)"
if [ "$got" != "22:00-07:00" ]; then
  echo "The item was written but could not be read back by its string key (got: $got)."
  exit 1
fi

keys="$(aws_local dynamodb describe-table --table-name postbox-prefs \
  --query 'length(Table.KeySchema)' --output text)"
if [ "$keys" != "1" ]; then
  echo "The service addresses riders by recipientId alone; the table should have only a partition key."
  exit 1
fi

aws_local dynamodb delete-item --table-name postbox-prefs --key "{\"recipientId\":{\"S\":\"$rider\"}}" >/dev/null
echo "postbox-prefs now stores riders by UUID string. Notifications can be configured."
