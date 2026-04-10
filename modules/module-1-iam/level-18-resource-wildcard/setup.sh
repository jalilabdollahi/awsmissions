#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source ../../../scripts/aws_helpers.sh

aws_local s3 mb s3://bucket >/dev/null 2>&1 || true
printf 'one
' > /tmp/iam18.txt
aws_local s3 cp /tmp/iam18.txt s3://bucket/specific.txt >/dev/null
aws_local iam create-role   --role-name object-scope-role   --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":"arn:aws:iam::000000000000:root"},"Action":"sts:AssumeRole"}]}' >/dev/null 2>&1 || true
aws_local iam put-role-policy   --role-name object-scope-role   --policy-name object-scope-policy   --policy-document "file://$SCRIPT_DIR/policy.json" >/dev/null

echo "Broken IAM role created: object-scope-role"
