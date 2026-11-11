#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# Find the retired key by its description.
old_id=""
for id in $(aws_local kms list-keys --query 'Keys[].KeyId' --output text); do
  d="$(aws_local kms describe-key --key-id "$id" --query KeyMetadata.Description --output text 2>/dev/null || true)"
  if [ "$d" = "Atlas archive key (2021, retired)" ]; then old_id="$id"; fi
done

# Re-encrypt needs the source key usable for a moment.
aws_local kms enable-key --key-id "$old_id"

blob=""
for n in 1 2 3; do
  old="$(aws_local ssm get-parameter --name "/atlas/archive/record-$n" --query Parameter.Value --output text)"
  python3 -c 'import sys,base64; sys.stdout.buffer.write(base64.b64decode(sys.argv[1]))' "$old" > record.bin
  new="$(aws_local kms re-encrypt --ciphertext-blob fileb://record.bin \
    --source-encryption-context dataset=atlas-archive \
    --destination-key-id alias/atlas-data \
    --destination-encryption-context dataset=atlas-archive \
    --query CiphertextBlob --output text)"
  aws_local ssm put-parameter --name "/atlas/archive/record-$n" --type String --value "$new" --overwrite >/dev/null
done
rm -f record.bin

aws_local kms disable-key --key-id "$old_id"
current_id="$(aws_local kms describe-key --key-id alias/atlas-data --query KeyMetadata.KeyId --output text)"
aws_local kms enable-key-rotation --key-id "$current_id"
