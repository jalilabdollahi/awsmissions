#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local s3 mb s3://northwind-metrics-export >/dev/null
seed="$(mktemp)"
trap 'rm -f "$seed"' EXIT
echo 'store,basket_size
12,34.1' > "$seed"
aws_local s3api put-object --bucket northwind-metrics-export --key daily/2025-11-10.csv --body "$seed" >/dev/null

aws_local iam create-user --user-name metricwave-svc >/dev/null
aws_local iam put-user-policy --user-name metricwave-svc --policy-name assume-northwind \
  --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Resource\":\"arn:aws:iam::${ACCOUNT_ID}:role/metricwave-reader\"}]}"

aws_local iam create-role --role-name metricwave-reader \
  --assume-role-policy-document "file://$MISSION_DIR/workspace/trust-policy.json" >/dev/null
aws_local iam put-role-policy --role-name metricwave-reader --policy-name read-export \
  --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["s3:ListBucket"],"Resource":"arn:aws:s3:::northwind-metrics-export"},{"Effect":"Allow","Action":"s3:GetObject","Resource":"arn:aws:s3:::northwind-metrics-export/*"}]}'

echo "metricwave-reader is live; the vendor's handshake is rejected."
