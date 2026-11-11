#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

new_arn="$(aws_local kms describe-key --key-id alias/atlas-data --query KeyMetadata.Arn --output text 2>/dev/null || true)"
if [ -z "$new_arn" ]; then
  echo "alias/atlas-data no longer exists."
  exit 1
fi
new_id="${new_arn##*/}"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
n=1
for want in "patient-1001:blood=O+" "patient-1002:blood=A-" "patient-1003:blood=B+"; do
  blob="$(aws_local ssm get-parameter --name "/atlas/archive/record-$n" --query Parameter.Value --output text 2>/dev/null || true)"
  if [ -z "$blob" ]; then
    echo "/atlas/archive/record-$n has been removed."
    exit 1
  fi
  python3 -c 'import sys,base64; sys.stdout.buffer.write(base64.b64decode(sys.argv[1]))' "$blob" > "$tmp"
  if ! res="$(aws_local kms decrypt --ciphertext-blob "fileb://$tmp" \
        --encryption-context dataset=atlas-archive --output json 2>&1)"; then
    echo "record-$n does not decrypt: $(printf '%s' "$res" | tail -1)"
    exit 1
  fi
  if [ "$(printf '%s' "$res" | jq -r .Plaintext | base64 -d)" != "$want" ]; then
    echo "record-$n decrypts to the wrong plaintext."
    exit 1
  fi
  used="$(printf '%s' "$res" | jq -r .KeyId)"
  if [ "$used" != "$new_arn" ]; then
    echo "record-$n is still encrypted under an older key. It has to be re-encrypted under the key behind alias/atlas-data."
    exit 1
  fi
  n=$((n + 1))
done

# The old key: retired, but not destroyed.
old_id=""
for id in $(aws_local kms list-keys --query 'Keys[].KeyId' --output text); do
  d="$(aws_local kms describe-key --key-id "$id" --query KeyMetadata.Description --output text 2>/dev/null || true)"
  if [ "$d" = "Atlas archive key (2021, retired)" ]; then old_id="$id"; fi
done
if [ -z "$old_id" ]; then
  echo "The retired key is gone. Keys must be disabled, not deleted: older backups may still depend on them."
  exit 1
fi
old_state="$(aws_local kms describe-key --key-id "$old_id" --query KeyMetadata.Enabled --output text)"
if [ "$old_state" = "True" ] || [ "$old_state" = "true" ]; then
  echo "The retired key is enabled. Once the data is migrated it should be switched off again."
  exit 1
fi
if aws_local kms describe-key --key-id "$old_id" --query KeyMetadata.KeyState --output text | grep -q PendingDeletion; then
  echo "The retired key is scheduled for deletion. Disable it, but do not schedule deletion yet."
  exit 1
fi

rotation="$(aws_local kms get-key-rotation-status --key-id "$new_id" --query KeyRotationEnabled --output text)"
if [ "$rotation" != "True" ] && [ "$rotation" != "true" ]; then
  echo "Automatic rotation is not enabled on the current key, so the next rotation would repeat this incident."
  exit 1
fi

echo "All records live under the current key, the old key is retired, and rotation is automatic from now on."
