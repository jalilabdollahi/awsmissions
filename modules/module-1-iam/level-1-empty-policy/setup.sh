#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local s3 mb s3://harborline-reports >/dev/null
aws_local s3 mb s3://harborline-payroll >/dev/null

seed="$(mktemp)"
trap 'rm -f "$seed"' EXIT
printf 'lane,teu,margin\nRTM-NYC,412,0.18\nSIN-LAX,377,0.22\n' > "$seed"
aws_local s3api put-object --bucket harborline-reports --key reports/2025-q3.csv --body "$seed" >/dev/null
printf 'employee,salary\nredacted,redacted\n' > "$seed"
aws_local s3api put-object --bucket harborline-payroll --key payroll/2025-09.csv --body "$seed" >/dev/null

aws_local iam create-user --user-name ledgerlens-report >/dev/null
aws_local iam put-user-policy --user-name ledgerlens-report --policy-name report-access \
  --policy-document "file://$MISSION_DIR/workspace/policy.json"

echo "ledgerlens-report can list harborline-reports but cannot open a single report."
