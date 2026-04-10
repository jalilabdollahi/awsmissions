#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

aws_local s3 mb s3://mission-bucket >/dev/null 2>&1 || true
aws_local iam create-role   --role-name bloated-role   --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":"arn:aws:iam::000000000000:root"},"Action":"sts:AssumeRole"}]}' >/dev/null 2>&1 || true

echo "Broken IAM role created: bloated-role (inline policy was too large to attach)"
