#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

role_arn="arn:aws:iam::${ACCOUNT_ID}:role/metricwave-reader"
dest="$(mktemp)"
trap 'rm -f "$dest"' EXIT
vendor_id="mw-5d1f-prod-8841"

rc=0
aws_as_role "$role_arn" metricwave-svc "$vendor_id" s3api get-object --bucket northwind-metrics-export \
  --key daily/2025-11-10.csv "$dest" >/dev/null 2>&1 || rc=$?
if [ "$rc" -eq 98 ]; then
  echo "assume-role with the vendor's external ID is still refused."
  echo "Compare the value the vendor sends with what the role's trust policy expects, character by character."
  exit 1
elif [ "$rc" -ne 0 ]; then
  echo "The role was assumed but reading the export failed (exit $rc). The permissions policy is not the issue."
  exit 1
fi
if ! grep -q basket_size "$dest"; then
  echo "Assumed the role, but the export content looks wrong."
  exit 1
fi

# The point of the external ID: callers that do not know it are turned away.
rc=0
aws_as_role "$role_arn" metricwave-svc "" s3api list-buckets >/dev/null 2>&1 || rc=$?
if [ "$rc" -ne 98 ]; then
  echo "metricwave-svc can assume the role without any external ID. The condition is the whole protection against the confused deputy problem; keep it."
  exit 1
fi
rc=0
aws_as_role "$role_arn" metricwave-svc "some-other-customers-id" s3api list-buckets >/dev/null 2>&1 || rc=$?
if [ "$rc" -ne 98 ]; then
  echo "The role accepts an arbitrary external ID. It must require exactly the one MetricWave was given."
  exit 1
fi

echo "metricwave-svc assumes the role only with the agreed external ID, and the export is readable."
