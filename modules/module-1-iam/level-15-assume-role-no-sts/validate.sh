#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

audit_arn="arn:aws:iam::${ACCOUNT_ID}:role/cobalt-audit-readonly"
admin_arn="arn:aws:iam::${ACCOUNT_ID}:role/cobalt-finance-admin"
dest="$(mktemp)"
trap 'rm -f "$dest"' EXIT

# Did anyone "fix" the wrong side by rewriting the roles' trust? Both must still trust the account root.
for r in cobalt-audit-readonly cobalt-finance-admin; do
  if ! aws_local iam get-role --role-name "$r" --query 'Role.AssumeRolePolicyDocument' --output json | grep -q ':root'; then
    echo "The trust policy of $r was changed. The roles were fine; the auditor's own permissions are what is missing."
    exit 1
  fi
done

rc=0
aws_as_role "$audit_arn" cobalt-auditor "" s3api get-object --bucket cobalt-audit-logs \
  --key trail/2025-11-10.log "$dest" >/dev/null 2>&1 || rc=$?
if [ "$rc" -eq 98 ]; then
  echo "cobalt-auditor still cannot assume cobalt-audit-readonly."
  echo "A role trusting the account is only half of the handshake: what does the auditor's own identity policy say about sts:AssumeRole?"
  exit 1
elif [ "$rc" -ne 0 ]; then
  echo "The role was assumed but reading the audit log failed (exit $rc). The role's permissions are not the problem."
  exit 1
fi
if ! grep -q 'wire-transfer' "$dest"; then
  echo "Assumed the role, but the log content is not what was expected."
  exit 1
fi

rc=0
aws_as_role "$admin_arn" cobalt-auditor "" s3api list-buckets >/dev/null 2>&1 || rc=$?
if [ "$rc" -ne 98 ]; then
  echo "cobalt-auditor can assume cobalt-finance-admin too. An external auditor must only reach the read-only role."
  exit 1
fi

echo "cobalt-auditor switches into cobalt-audit-readonly and reads the logs; the finance admin role stays out of reach."
