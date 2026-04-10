#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source ../../../scripts/aws_helpers.sh

aws_local s3 mb s3://mission-bucket >/dev/null 2>&1 || true
aws_local iam create-role   --role-name conflicted-reader-role   --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":"arn:aws:iam::000000000000:root"},"Action":"sts:AssumeRole"}]}' >/dev/null 2>&1 || true
aws_local iam put-role-policy   --role-name conflicted-reader-role   --policy-name allow-reader-policy   --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:GetObject","Resource":"arn:aws:s3:::mission-bucket/*"}]}' >/dev/null
aws_local iam put-role-policy   --role-name conflicted-reader-role   --policy-name conflicting-policy   --policy-document "file://$SCRIPT_DIR/policy.json" >/dev/null

echo "Broken IAM role created: conflicted-reader-role"
