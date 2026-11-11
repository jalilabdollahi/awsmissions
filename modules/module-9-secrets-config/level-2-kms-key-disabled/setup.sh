#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

key_id="$(aws_local kms create-key --description "Marigold Pay card-token key" \
  --query KeyMetadata.KeyId --output text)"
aws_local kms create-alias --alias-name alias/marigold-tokens --target-key-id "$key_id"

n=1
for token in tok_4111_a9f3 tok_5500_77c1 tok_3782_0be4; do
  blob="$(aws_local kms encrypt --key-id alias/marigold-tokens \
    --plaintext "$(printf '%s' "$token" | base64)" --query CiphertextBlob --output text)"
  aws_local ssm put-parameter --name "/marigold/tokens/$n" --type String --value "$blob" >/dev/null
  n=$((n + 1))
done

# The overnight clean-up job.
aws_local kms disable-key --key-id "$key_id"
echo "The tokens are stored; the key behind alias/marigold-tokens has been switched off."
