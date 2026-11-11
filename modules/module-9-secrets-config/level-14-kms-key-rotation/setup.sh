#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

old_key="$(aws_local kms create-key --description "Atlas archive key (2021, retired)" \
  --query KeyMetadata.KeyId --output text)"
new_key="$(aws_local kms create-key --description "Atlas archive key (2024, current)" \
  --query KeyMetadata.KeyId --output text)"
aws_local kms create-alias --alias-name alias/atlas-data --target-key-id "$new_key"

# Three archive records written years ago under the old key.
n=1
for record in "patient-1001:blood=O+" "patient-1002:blood=A-" "patient-1003:blood=B+"; do
  blob="$(aws_local kms encrypt --key-id "$old_key" --encryption-context dataset=atlas-archive \
    --plaintext "$(printf '%s' "$record" | base64)" --query CiphertextBlob --output text)"
  aws_local ssm put-parameter --name "/atlas/archive/record-$n" --type String --value "$blob" >/dev/null
  n=$((n + 1))
done

# The manual "rotation" runbook, step 3: retire the old key.
aws_local kms disable-key --key-id "$old_key"
echo "Archive records are under a disabled key; alias/atlas-data points at the new one."
