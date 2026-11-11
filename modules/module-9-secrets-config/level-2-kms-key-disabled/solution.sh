#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

key_id="$(aws_local kms describe-key --key-id alias/marigold-tokens \
  --query KeyMetadata.KeyId --output text)"
aws_local kms enable-key --key-id "$key_id"
