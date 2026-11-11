#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

meta="$(aws_local kms describe-key --key-id alias/lanternfish-vault --query KeyMetadata --output json 2>/dev/null || true)"
if [ -z "$meta" ]; then
  echo "alias/lanternfish-vault still does not resolve to a key."
  exit 1
fi

key_id="$(printf '%s' "$meta" | jq -r '.KeyId')"
if [ "$(printf '%s' "$meta" | jq -r '.KeyManager')" != "CUSTOMER" ]; then
  echo "The alias must point at a customer-managed key."
  exit 1
fi
if [ "$(printf '%s' "$meta" | jq -r '.KeyState')" != "Enabled" ]; then
  echo "The key behind the alias is $(printf '%s' "$meta" | jq -r '.KeyState'), not Enabled."
  exit 1
fi
if [ "$(printf '%s' "$meta" | jq -r '.KeySpec')" != "SYMMETRIC_DEFAULT" ] || \
   [ "$(printf '%s' "$meta" | jq -r '.KeyUsage')" != "ENCRYPT_DECRYPT" ]; then
  echo "The vault needs a symmetric key used for ENCRYPT_DECRYPT."
  exit 1
fi

rotation="$(aws_local kms get-key-rotation-status --key-id "$key_id" --query KeyRotationEnabled --output text 2>/dev/null || true)"
if [ "$rotation" != "True" ] && [ "$rotation" != "true" ]; then
  echo "The key works but automatic rotation is not enabled; security requires it."
  exit 1
fi

# Round trip through the alias, exactly like the vault does.
plain="contract-$(date +%s)"
blob="$(aws_local kms encrypt --key-id alias/lanternfish-vault \
  --plaintext "$(printf '%s' "$plain" | base64)" --query CiphertextBlob --output text 2>/dev/null || true)"
if [ -z "$blob" ]; then
  echo "Encrypting through alias/lanternfish-vault failed."
  exit 1
fi
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
python3 -c 'import sys,base64; sys.stdout.buffer.write(base64.b64decode(sys.argv[1]))' "$blob" > "$tmp"
back="$(aws_local kms decrypt --ciphertext-blob "fileb://$tmp" --query Plaintext --output text | base64 -d)"
if [ "$back" != "$plain" ]; then
  echo "Decrypting did not return the original data."
  exit 1
fi

echo "alias/lanternfish-vault resolves to an enabled, rotating symmetric key, and data round-trips through it."
