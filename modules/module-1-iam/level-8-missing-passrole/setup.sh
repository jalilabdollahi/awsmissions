#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

aws_local iam create-user --user-name mission-deployer >/dev/null 2>&1 || true
aws_local iam create-role   --role-name lambda-execution-role   --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null 2>&1 || true

aws_local iam put-user-policy   --user-name mission-deployer   --policy-name deployer-policy   --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"lambda:CreateFunction","Resource":"*"}]}' >/dev/null

echo "Broken IAM user created: mission-deployer (missing iam:PassRole)"
