#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

B=meridian-audit-reports
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
echo probe > "$work/probe.txt"

try_get() { # user key
  aws_as_user "$1" s3api get-object --bucket "$B" --key "$2" "$work/out" >/dev/null 2>&1
}

if ! try_get auditor-dana reports/q3-2026.txt; then
  echo "auditor-dana still gets AccessDenied on reports/q3-2026.txt. Check who the policy names as Principal and which keys the Resource covers."
  exit 1
fi
if ! try_get auditor-dana reports/archive/q2-2026.txt; then
  echo "auditor-dana can read the top of reports/ but not the nested archive. The Resource must cover everything below the reports/ prefix."
  exit 1
fi
if try_get auditor-dana payroll/2026-10.csv; then
  echo "auditor-dana can now read payroll/. The auditor must only see reports/."
  exit 1
fi
if try_get intern-lee reports/q3-2026.txt; then
  echo "intern-lee can read the audit packs. The grant must name only the auditor, not everyone."
  exit 1
fi
if aws_as_user auditor-dana s3api put-object --bucket "$B" --key reports/forged.txt --body "$work/probe.txt" >/dev/null 2>&1; then
  echo "auditor-dana can write into the bucket. Dana only needs to download."
  exit 1
fi
echo "auditor-dana reads reports/ and nothing else. Payroll is still locked away."
