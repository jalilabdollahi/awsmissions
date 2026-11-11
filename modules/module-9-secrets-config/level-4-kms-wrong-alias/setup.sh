#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

prod_key="$(aws_local kms create-key --description "Ironbridge orders - PRODUCTION data key" \
  --tags TagKey=env,TagValue=prod TagKey=service,TagValue=orders \
  --query KeyMetadata.KeyId --output text)"
staging_key="$(aws_local kms create-key --description "Ironbridge orders - staging data key" \
  --tags TagKey=env,TagValue=staging TagKey=service,TagValue=orders \
  --query KeyMetadata.KeyId --output text)"

# A production record from before the tidy-up, encrypted with the production key.
blob="$(aws_local kms encrypt --key-id "$prod_key" \
  --plaintext "$(printf 'order-90017:ship-to-cork' | base64)" --query CiphertextBlob --output text)"
aws_local ssm put-parameter --name /orders/prod/sample-record --type String --value "$blob" >/dev/null

# The tidy-up: both aliases now point at the staging key.
aws_local kms create-alias --alias-name alias/orders-staging --target-key-id "$staging_key"
aws_local kms create-alias --alias-name alias/orders-prod --target-key-id "$staging_key"

echo "alias/orders-prod and alias/orders-staging currently share one key."
