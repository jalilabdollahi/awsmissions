#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
B=fennel-ledger-archive

aws_local s3api create-bucket --bucket "$B" --object-lock-enabled-for-bucket >/dev/null
aws_local s3api put-object-lock-configuration --bucket "$B" --object-lock-configuration \
  '{"ObjectLockEnabled":"Enabled","Rule":{"DefaultRetention":{"Mode":"GOVERNANCE","Days":30}}}'

put_locked() { # key content
  printf '%s\n' "$2" > "$work/body"
  aws_local s3api put-object --bucket "$B" --key "$1" --body "$work/body" \
    --object-lock-mode GOVERNANCE --object-lock-retain-until-date 2028-01-01T00:00:00Z >/dev/null
}
put_locked ledger/2024-fy.csv "account,balance (FY2024)"
put_locked ledger/2025-fy.csv "account,balance (FY2025 draft)"
put_locked ledger/2025-fy.csv "account,balance (FY2025 audited)"

echo "The ledger archive is locked, but only in GOVERNANCE mode."
