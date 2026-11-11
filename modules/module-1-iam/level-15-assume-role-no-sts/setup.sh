#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local s3 mb s3://cobalt-audit-logs >/dev/null
seed="$(mktemp)"
trap 'rm -f "$seed"' EXIT
echo '2025-11-10T08:14Z wire-transfer approved' > "$seed"
aws_local s3api put-object --bucket cobalt-audit-logs --key trail/2025-11-10.log --body "$seed" >/dev/null

same_account_trust="{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::${ACCOUNT_ID}:root\"},\"Action\":\"sts:AssumeRole\"}]}"
aws_local iam create-role --role-name cobalt-audit-readonly --assume-role-policy-document "$same_account_trust" >/dev/null
aws_local iam put-role-policy --role-name cobalt-audit-readonly --policy-name read-audit-logs \
  --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["s3:ListBucket"],"Resource":"arn:aws:s3:::cobalt-audit-logs"},{"Effect":"Allow","Action":"s3:GetObject","Resource":"arn:aws:s3:::cobalt-audit-logs/*"}]}'
aws_local iam create-role --role-name cobalt-finance-admin --assume-role-policy-document "$same_account_trust" >/dev/null
aws_local iam attach-role-policy --role-name cobalt-finance-admin \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

aws_local iam create-user --user-name cobalt-auditor >/dev/null
aws_local iam put-user-policy --user-name cobalt-auditor --policy-name auditor-base \
  --policy-document "file://$MISSION_DIR/workspace/policy.json"

echo "cobalt-auditor can sign in; cobalt-audit-readonly trusts the account; the switch is refused."
