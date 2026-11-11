#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/orbit-report-writer"
ROOT_ARN="arn:aws:iam::${ACCOUNT_ID}:root"
ADMIN_ARN="arn:aws:iam::${ACCOUNT_ID}:user/key-admin"

key_id="$(aws_local kms describe-key --key-id alias/orbit-reports --query KeyMetadata.KeyId --output text 2>/dev/null || true)"
if [ -z "$key_id" ]; then
  echo "alias/orbit-reports is gone; the key must stay in place."
  exit 1
fi
policy="$(aws_local kms get-key-policy --key-id "$key_id" --policy-name default --query Policy --output text)"

report="$(printf '%s' "$policy" | jq -r --arg role "$ROLE_ARN" --arg root "$ROOT_ARN" --arg admin "$ADMIN_ARN" '
  def acts: (if (.Action|type)=="array" then .Action else [.Action] end);
  def who: ((if (.Principal|type)=="object" then (.Principal.AWS // []) else .Principal end) | if type=="array" then . else [.] end);
  def can($a): [acts[] | select(. as $p | ($p | gsub("\\*"; ".*")) as $re | $a | test("^" + $re + "$"; "i"))] | length > 0;
  def crypto: can("kms:Encrypt") and can("kms:Decrypt") and can("kms:GenerateDataKey");
  [.Statement[] | select(.Effect=="Allow")] as $allow
  | {
      open:     ($allow | any(.[]; (who | index("*")) != null and (has("Condition") | not))),
      admin:    ($allow | any(.[]; (who | index($admin)) != null and can("kms:PutKeyPolicy"))),
      delegated:($allow | any(.[]; (who | index($root)) != null and crypto)),
      direct:   ($allow | any(.[]; (who | index($role)) != null and crypto)),
      rolewild: ($allow | any(.[]; (who | index($role)) != null and (acts | index("kms:*")) != null))
    } | "\(.open) \(.admin) \(.delegated) \(.direct) \(.rolewild)"')"
set -- $report
open="$1"; admin="$2"; delegated="$3"; direct="$4"; rolewild="$5"

if [ "$open" = "true" ]; then
  echo "The key policy allows everyone (Principal \"*\") without a condition. That is far too open."
  exit 1
fi
if [ "$admin" != "true" ]; then
  echo "key-admin can no longer manage the key. Keep the administrator statement."
  exit 1
fi
if [ "$rolewild" = "true" ]; then
  echo "orbit-report-writer was given kms:* on the key. It should only use the key (encrypt, decrypt, generate data keys), not administer it."
  exit 1
fi
if [ "$delegated" != "true" ] && [ "$direct" != "true" ]; then
  echo "Nothing in the key policy lets orbit-report-writer (or IAM policies of this account) use the key for encrypt/decrypt/GenerateDataKey."
  exit 1
fi

# The role must still work end to end.
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
blob="$(aws_as_role "$ROLE_ARN" orbit-reporting-svc "" kms encrypt --key-id alias/orbit-reports \
  --plaintext "$(printf 'report-2024' | base64)" --query CiphertextBlob --output text 2>&1)" || {
  echo "As orbit-report-writer, encrypting with the key failed: $(printf '%s' "$blob" | tail -1)"
  exit 1
}
python3 -c 'import sys,base64; sys.stdout.buffer.write(base64.b64decode(sys.argv[1]))' "$blob" > "$tmp"
back="$(aws_as_role "$ROLE_ARN" orbit-reporting-svc "" kms decrypt --ciphertext-blob "fileb://$tmp" --query Plaintext --output text | base64 -d)"
if [ "$back" != "report-2024" ]; then
  echo "Decrypting as orbit-report-writer did not return the original data."
  exit 1
fi

echo "The key policy now lets orbit-report-writer use the key, key-admin still administers it, and the key is not open to the world."
