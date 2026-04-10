#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

aws_local s3 mb s3://mission-bucket >/dev/null 2>&1 || true
printf 'classified\n' > /tmp/awsmissions-data.txt
aws_local s3 cp /tmp/awsmissions-data.txt s3://mission-bucket/data.txt >/dev/null

aws_local iam create-role \
  --role-name report-reader-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":"arn:aws:iam::000000000000:root"},"Action":"sts:AssumeRole"}]}' >/dev/null 2>&1 || true

for _ in {1..10}; do
  if aws_local iam get-role --role-name report-reader-role >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

aws_local iam put-role-policy \
  --role-name report-reader-role \
  --policy-name report-reader-policy \
  --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:ListBucket","Resource":"arn:aws:s3:::mission-bucket"}]}' >/dev/null

echo "Broken IAM role created: report-reader-role"
