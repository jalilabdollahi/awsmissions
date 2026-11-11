#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

dest="$(mktemp)"
trap 'rm -f "$dest"' EXIT
ops() { aws_as_user fleet-ops "$@"; }

missing=""
for r in use1 use2 usw1 usw2 euw1 euw2 euc1 aps1 apse1 apse2 apne1 sae1 cac1 mes1; do
  b="fleet-$r-telemetry"
  if ! ops s3api get-object --bucket "$b" --key vehicles/v-001.csv "$dest" >/dev/null 2>&1; then
    missing="$missing $r"
  fi
done
if [ -n "$missing" ]; then
  echo "fleet-ops still cannot read telemetry from these regions:$missing"
  echo "Try attaching the draft yourself and read what IAM answers."
  exit 1
fi
if ! ops s3api list-objects-v2 --bucket fleet-euw1-telemetry >/dev/null 2>&1; then
  echo "Objects can be read but fleet-ops cannot list a telemetry bucket."
  exit 1
fi

if ops s3api get-object --bucket fleet-payroll --key drivers/2025-10.csv "$dest" >/dev/null 2>&1; then
  echo "fleet-ops can read fleet-payroll. A wildcard that is too wide on the bucket name was used; the payroll bucket must stay private."
  exit 1
fi
if ops s3api list-objects-v2 --bucket fleet-payroll >/dev/null 2>&1; then
  echo "fleet-ops can list fleet-payroll. Keep that bucket completely out of reach."
  exit 1
fi
if ops s3api put-object --bucket fleet-use1-telemetry --key vehicles/x.csv --body "$dest" >/dev/null 2>&1; then
  echo "fleet-ops can write to a telemetry bucket. Analytics should only read."
  exit 1
fi

echo "fleet-ops reads all fourteen telemetry buckets and cannot see payroll."
