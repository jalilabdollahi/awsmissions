#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

state="$(aws_local kms describe-key --key-id alias/marigold-tokens \
  --query KeyMetadata.KeyState --output text 2>/dev/null || true)"
if [ -z "$state" ]; then
  echo "alias/marigold-tokens no longer resolves to a key."
  exit 1
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
expected="tok_4111_a9f3 tok_5500_77c1 tok_3782_0be4"
n=1
for want in $expected; do
  blob="$(aws_local ssm get-parameter --name "/marigold/tokens/$n" --query Parameter.Value --output text 2>/dev/null || true)"
  if [ -z "$blob" ]; then
    echo "The stored token /marigold/tokens/$n has disappeared."
    exit 1
  fi
  python3 -c 'import sys,base64; sys.stdout.buffer.write(base64.b64decode(sys.argv[1]))' "$blob" > "$tmp"
  if ! got="$(aws_local kms decrypt --ciphertext-blob "fileb://$tmp" --query Plaintext --output text 2>&1)"; then
    echo "Decrypting /marigold/tokens/$n fails (key state: $state)."
    echo "KMS said: $(printf '%s' "$got" | tail -1)"
    exit 1
  fi
  if [ "$(printf '%s' "$got" | base64 -d)" != "$want" ]; then
    echo "/marigold/tokens/$n decrypts to something unexpected."
    exit 1
  fi
  n=$((n + 1))
done

echo "All three tokens decrypt to their original values."
