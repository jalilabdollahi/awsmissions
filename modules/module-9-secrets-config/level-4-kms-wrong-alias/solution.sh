#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# Identify the production key by its tag, then repoint the alias.
prod_key="$(aws_local kms list-keys --query 'Keys[].KeyId' --output text | tr '\t' '\n' | while read -r id; do
  [ -z "$id" ] && continue
  if [ "$(aws_local kms list-resource-tags --key-id "$id" \
        --query "Tags[?TagKey=='env'].TagValue | [0]" --output text 2>/dev/null)" = "prod" ]; then
    echo "$id"
  fi
done | head -1)"

aws_local kms update-alias --alias-name alias/orders-prod --target-key-id "$prod_key"
