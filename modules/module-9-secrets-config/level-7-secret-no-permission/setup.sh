#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local secretsmanager create-secret --name quokka/prod/payments-api \
  --secret-string '{"processor_token":"pt_live_81kd02"}' >/dev/null
aws_local secretsmanager create-secret --name quokka/prod/admin-console \
  --secret-string '{"admin_password":"never-for-the-api"}' >/dev/null
aws_local secretsmanager create-secret --name quokka/staging/payments-api \
  --secret-string '{"processor_token":"pt_test_00aa11"}' >/dev/null

aws_local iam create-user --user-name quokka-deployer >/dev/null
aws_local iam put-user-policy --user-name quokka-deployer --policy-name assume-api \
  --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Resource\":\"arn:aws:iam::${ACCOUNT_ID}:role/quokka-api\"}]}"
aws_local iam create-role --role-name quokka-api \
  --assume-role-policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::${ACCOUNT_ID}:user/quokka-deployer\"},\"Action\":\"sts:AssumeRole\"}]}" >/dev/null
aws_local iam put-role-policy --role-name quokka-api --policy-name quokka-secrets \
  --policy-document "file://$MISSION_DIR/workspace/policy.json"

echo "quokka-api cannot read its payments secret any more."
