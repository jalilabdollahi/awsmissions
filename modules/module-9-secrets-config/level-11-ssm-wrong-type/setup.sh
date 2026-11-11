#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

key_id="$(aws_local kms create-key --description "Harrier configuration secrets" \
  --query KeyMetadata.KeyId --output text)"
aws_local kms create-alias --alias-name alias/harrier-config --target-key-id "$key_id"

aws_local ssm put-parameter --name /harrier/payments/api-key --type String \
  --value "hk_live_77Q2xvNdw" --description "Card processor API key" >/dev/null
aws_local ssm put-parameter --name /harrier/payments/timeout-ms --type String \
  --value "2500" >/dev/null

echo "The API key sits in Parameter Store as plain text."
