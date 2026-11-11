#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local iam create-user --user-name key-admin >/dev/null
aws_local iam create-user --user-name orbit-reporting-svc >/dev/null
aws_local iam create-role --role-name orbit-report-writer \
  --assume-role-policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::${ACCOUNT_ID}:user/orbit-reporting-svc\"},\"Action\":\"sts:AssumeRole\"}]}" >/dev/null
aws_local iam put-user-policy --user-name orbit-reporting-svc --policy-name assume-writer \
  --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Resource\":\"arn:aws:iam::${ACCOUNT_ID}:role/orbit-report-writer\"}]}"
aws_local iam put-role-policy --role-name orbit-report-writer --policy-name use-report-key \
  --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["kms:Encrypt","kms:Decrypt","kms:GenerateDataKey","kms:DescribeKey"],"Resource":"*"}]}'

# The key, created with the admin-only policy from the workspace.
key_id="$(aws_local kms create-key --description "Orbit Health patient reports" \
  --policy "file://$MISSION_DIR/workspace/key-policy.json" --query KeyMetadata.KeyId --output text)"
aws_local kms create-alias --alias-name alias/orbit-reports --target-key-id "$key_id"

echo "alias/orbit-reports exists with an administrators-only key policy."
