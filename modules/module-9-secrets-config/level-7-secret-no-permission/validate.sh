#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/quokka-api"

read_as_role() {
  aws_as_role "$ROLE_ARN" quokka-deployer "" secretsmanager get-secret-value --secret-id "$1" \
    --query SecretString --output text 2>&1
}

set +e
out="$(read_as_role quokka/prod/payments-api)"
rc=$?
set -e
if [ "$rc" -eq 98 ]; then
  echo "quokka-deployer can no longer assume quokka-api; leave the trust policy alone."
  exit 1
fi
if [ "$rc" -ne 0 ]; then
  echo "quokka-api still cannot read quokka/prod/payments-api: $(printf '%s' "$out" | tail -1)"
  exit 1
fi
case "$out" in
  *pt_live_81kd02*) ;;
  *) echo "The role read something, but not the production token."; exit 1 ;;
esac

if read_as_role quokka/prod/admin-console >/dev/null 2>&1; then
  echo "quokka-api can now read the admin console secret too. Scope the permission to the payments secret only."
  exit 1
fi
if read_as_role quokka/staging/payments-api >/dev/null 2>&1; then
  echo "quokka-api can read the staging secret as well. Production roles should not need it."
  exit 1
fi

echo "quokka-api reads quokka/prod/payments-api and nothing else."
