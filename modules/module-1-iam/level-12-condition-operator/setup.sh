#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source ../../../scripts/aws_helpers.sh

aws_local s3 mb s3://mission-bucket >/dev/null 2>&1 || true
aws_local iam create-role   --role-name prefix-reader-role   --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":"arn:aws:iam::000000000000:root"},"Action":"sts:AssumeRole"}]}' >/dev/null 2>&1 || true
aws_local iam put-role-policy   --role-name prefix-reader-role   --policy-name prefix-reader-policy   --policy-document "file://$SCRIPT_DIR/policy.json" >/dev/null

echo "Broken IAM role created: prefix-reader-role"
