#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

aws_local s3 mb s3://meridian-audit-reports >/dev/null
echo "Q3 2026 audit pack - claims reserves" > "$work/q3.txt"
echo "Q2 2026 audit pack - claims reserves" > "$work/q2.txt"
echo "emp_id,salary" > "$work/payroll.csv"
aws_local s3 cp "$work/q3.txt" s3://meridian-audit-reports/reports/q3-2026.txt >/dev/null
aws_local s3 cp "$work/q2.txt" s3://meridian-audit-reports/reports/archive/q2-2026.txt >/dev/null
aws_local s3 cp "$work/payroll.csv" s3://meridian-audit-reports/payroll/2026-10.csv >/dev/null

# Two bare users: they have no identity policies at all.
aws_local iam create-user --user-name auditor-dana >/dev/null
aws_local iam create-user --user-name intern-lee >/dev/null

# The policy that was applied during the Monday cleanup.
aws_local s3api put-bucket-policy --bucket meridian-audit-reports \
  --policy "file://$MISSION_DIR/workspace/bucket-policy.json"

echo "auditor-dana is getting AccessDenied on every download."
