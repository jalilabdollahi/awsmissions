#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

# Which key really is the production key? The one that opens the old production record.
old="$(aws_local ssm get-parameter --name /orders/prod/sample-record --query Parameter.Value --output text)"
python3 -c 'import sys,base64; sys.stdout.buffer.write(base64.b64decode(sys.argv[1]))' "$old" > "$tmp"
prod_arn="$(aws_local kms decrypt --ciphertext-blob "fileb://$tmp" --query KeyId --output text 2>/dev/null || true)"
if [ -z "$prod_arn" ]; then
  echo "The production key can no longer decrypt the old production record; it must stay enabled and intact."
  exit 1
fi

prod_target="$(aws_local kms describe-key --key-id alias/orders-prod --query KeyMetadata.Arn --output text 2>/dev/null || true)"
if [ -z "$prod_target" ]; then
  echo "alias/orders-prod does not exist any more."
  exit 1
fi
if [ "$prod_target" != "$prod_arn" ]; then
  echo "alias/orders-prod still resolves to a different key than the one holding the production records."
  exit 1
fi

staging_target="$(aws_local kms describe-key --key-id alias/orders-staging --query KeyMetadata.Arn --output text 2>/dev/null || true)"
if [ -z "$staging_target" ] || [ "$staging_target" = "$prod_arn" ]; then
  echo "alias/orders-staging must keep pointing at the staging key, not at production."
  exit 1
fi

# What the service does: new writes through the alias land under the production key.
used="$(aws_local kms encrypt --key-id alias/orders-prod \
  --plaintext "$(printf 'order-90018' | base64)" --query KeyId --output text)"
if [ "$used" != "$prod_arn" ]; then
  echo "A new encryption through alias/orders-prod used the wrong key."
  exit 1
fi

echo "alias/orders-prod encrypts under the production key again, and staging is untouched."
