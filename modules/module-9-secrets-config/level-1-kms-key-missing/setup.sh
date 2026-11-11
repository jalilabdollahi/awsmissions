#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# The vault has been calling KMS for hours already; show the player the error it sees.
if aws_local kms encrypt --key-id alias/lanternfish-vault \
     --plaintext "$(printf 'contract' | base64)" >/dev/null 2>&1; then
  echo "unexpected: the alias already exists" >&2
  exit 1
fi
echo "alias/lanternfish-vault does not exist; every vault upload is failing."
