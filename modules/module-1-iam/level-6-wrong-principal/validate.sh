#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

role_arn="arn:aws:iam::${ACCOUNT_ID}:role/ledger-nightly"
dest="$(mktemp)"
trap 'rm -f "$dest"' EXIT

if ! aws_local iam get-role --role-name ledger-nightly >/dev/null 2>&1; then
  echo "The role ledger-nightly is gone. Edit it; do not delete it."
  exit 1
fi

rc=0
aws_as_role "$role_arn" ledger-batch "" s3api get-object --bucket orbit-ledger-books \
  --key 2025/trial-balance.csv "$dest" >/dev/null 2>&1 || rc=$?
if [ "$rc" -eq 98 ]; then
  echo "ledger-batch still cannot assume ledger-nightly (AccessDenied from STS)."
  echo "Its own permission to call sts:AssumeRole is fine, so look at who the role says it trusts."
  exit 1
elif [ "$rc" -ne 0 ]; then
  echo "ledger-batch assumed the role but could not read the books (exit $rc). Do not touch the permissions policy."
  exit 1
fi
if ! grep -q 'balance' "$dest"; then
  echo "The role assumed fine, but the file read back is not the trial balance."
  exit 1
fi

# Lazy over-fix: trusting the whole account (or everyone) lets other callers in.
rc=0
aws_as_role "$role_arn" temp-auditor "" s3api list-buckets >/dev/null 2>&1 || rc=$?
if [ "$rc" -ne 98 ]; then
  echo "temp-auditor can assume ledger-nightly too. The trust policy is now broader than it needs to be: name ledger-batch only."
  exit 1
fi

echo "ledger-batch assumes ledger-nightly and reads the books; temp-auditor is still kept out."
