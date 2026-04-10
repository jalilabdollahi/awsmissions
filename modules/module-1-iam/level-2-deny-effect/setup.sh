#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

aws_local s3 mb s3://uploads-bucket >/dev/null 2>&1 || true

aws_local iam create-role \
  --role-name uploader-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":"arn:aws:iam::000000000000:root"},"Action":"sts:AssumeRole"}]}' >/dev/null 2>&1 || true

for _ in {1..10}; do
  if aws_local iam get-role --role-name uploader-role >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

aws_local iam put-role-policy \
  --role-name uploader-role \
  --policy-name uploader-policy \
  --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Deny","Action":["s3:PutObject"],"Resource":"arn:aws:s3:::uploads-bucket/*"}]}' >/dev/null

echo "Broken IAM role created: uploader-role"
