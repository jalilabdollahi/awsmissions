#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

describe() {
  aws_local ssm describe-parameters \
    --parameter-filters "Key=Name,Option=Equals,Values=$1" \
    --query 'Parameters[0].[Type,KeyId,Version]' --output text 2>/dev/null || true
}

info="$(describe /harrier/payments/api-key)"
if [ -z "$info" ] || [ "$info" = "None" ]; then
  echo "/harrier/payments/api-key no longer exists; the service still needs it."
  exit 1
fi
set -- $info
ptype="$1"; keyid="${2:-}"; version="${3:-1}"

if [ "$ptype" != "SecureString" ]; then
  echo "/harrier/payments/api-key is still a $ptype parameter; it must be encrypted."
  exit 1
fi
want_key="$(aws_local kms describe-key --key-id alias/harrier-config --query KeyMetadata.KeyId --output text 2>/dev/null || true)"
case "$keyid" in
  alias/harrier-config|*"$want_key"*) ;;
  *) echo "The parameter is encrypted, but with '$keyid' instead of the team's key alias/harrier-config."; exit 1 ;;
esac

value="$(aws_local ssm get-parameter --name /harrier/payments/api-key --with-decryption \
  --query Parameter.Value --output text)"
if [ "$value" != "hk_live_77Q2xvNdw" ]; then
  echo "The decrypted value is not the original API key; the processor would reject the service."
  exit 1
fi
if [ "$version" -lt 2 ]; then
  echo "The parameter still has its original version; overwrite the existing parameter (do not leave the plaintext one in place)."
  exit 1
fi

sibling="$(describe /harrier/payments/timeout-ms)"
if [ -z "$sibling" ] || [ "$sibling" = "None" ]; then
  echo "/harrier/payments/timeout-ms disappeared."
  exit 1
fi
if [ "$(printf '%s' "$sibling" | awk '{print $1}')" != "String" ]; then
  echo "/harrier/payments/timeout-ms was converted too. The legacy tool that reads it cannot decrypt; leave harmless settings as String."
  exit 1
fi

echo "The API key is a SecureString under alias/harrier-config with its value intact; the timeout stays a plain String."
