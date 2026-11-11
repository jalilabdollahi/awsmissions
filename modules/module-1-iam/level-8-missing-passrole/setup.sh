#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

lambda_trust='{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
aws_local iam create-role --role-name promo-fn-role --assume-role-policy-document "$lambda_trust" >/dev/null
aws_local iam put-role-policy --role-name promo-fn-role --policy-name logs-only \
  --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["logs:CreateLogStream","logs:PutLogEvents"],"Resource":"*"}]}'
aws_local iam create-role --role-name platform-admin-role --assume-role-policy-document "$lambda_trust" >/dev/null
aws_local iam attach-role-policy --role-name platform-admin-role \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

aws_local iam create-user --user-name kestrel-releaser >/dev/null
aws_local iam put-user-policy --user-name kestrel-releaser --policy-name release-pipeline \
  --policy-document "file://$MISSION_DIR/workspace/policy.json"

echo "kestrel-releaser can create functions but not attach any execution role."
