#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

aws_local iam create-user --user-name switcher-user >/dev/null 2>&1 || true
aws_local iam create-role   --role-name target-role   --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":"arn:aws:iam::000000000000:root"},"Action":"sts:AssumeRole"}]}' >/dev/null 2>&1 || true
aws_local iam put-user-policy   --user-name switcher-user   --policy-name switcher-policy   --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:ListBucket","Resource":"*"}]}' >/dev/null

echo "Broken IAM user created: switcher-user (missing sts:AssumeRole)"
