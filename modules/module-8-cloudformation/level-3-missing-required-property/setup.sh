#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local cloudformation delete-stack --stack-name lumen-export >/dev/null 2>&1 || true

# A bucket the exporter must never touch, plus two people with sts rights.
aws_local s3 mb s3://lumen-hr-records >/dev/null

aws_local iam create-user --user-name export-runner >/dev/null
aws_local iam put-user-policy --user-name export-runner --policy-name may-assume-exporter \
  --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Resource\":\"arn:aws:iam::${ACCOUNT_ID}:role/lumen-exporter\"}]}"

aws_local iam create-user --user-name intern-sandbox >/dev/null
aws_local iam put-user-policy --user-name intern-sandbox --policy-name assume-anything \
  --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"sts:AssumeRole","Resource":"*"}]}'

aws_local cloudformation create-stack --stack-name lumen-export \
  --template-body "file://$MISSION_DIR/workspace/template.yaml" \
  --capabilities CAPABILITY_NAMED_IAM >/dev/null
aws_local cloudformation wait stack-create-complete --stack-name lumen-export

echo "lumen-export is deployed. export-runner still cannot assume lumen-exporter."
