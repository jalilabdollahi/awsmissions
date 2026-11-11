#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

key_id="$(aws_local kms create-key --description "Lanternfish document vault" \
  --query KeyMetadata.KeyId --output text)"
aws_local kms create-alias --alias-name alias/lanternfish-vault --target-key-id "$key_id"
aws_local kms enable-key-rotation --key-id "$key_id"
