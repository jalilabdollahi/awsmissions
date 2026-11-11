#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

seed="$(mktemp)"
trap 'rm -f "$seed"' EXIT
echo 'ping,speed
1,88' > "$seed"
for r in use1 use2 usw1 usw2 euw1 euw2 euc1 aps1 apse1 apse2 apne1 sae1 cac1 mes1; do
  aws_local s3 mb "s3://fleet-$r-telemetry" >/dev/null
  aws_local s3api put-object --bucket "fleet-$r-telemetry" --key vehicles/v-001.csv --body "$seed" >/dev/null
done
aws_local s3 mb s3://fleet-payroll >/dev/null
aws_local s3api put-object --bucket fleet-payroll --key drivers/2025-10.csv --body "$seed" >/dev/null

aws_local iam create-user --user-name fleet-ops >/dev/null
aws_local iam put-user-policy --user-name fleet-ops --policy-name basics \
  --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:ListAllMyBuckets","Resource":"*"}]}'

echo "fleet-ops only has its basics policy; the 14-bucket draft is waiting in your workspace."
