#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

aws_local iam create-role \
  --role-name lambda-basic-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null 2>&1 || true

for _ in {1..10}; do
  if aws_local iam get-role --role-name lambda-basic-role >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

echo "Broken IAM role created: lambda-basic-role (no policies attached)"
