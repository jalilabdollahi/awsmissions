#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local s3 mb s3://quasar-audit-records >/dev/null
aws_local ssm put-parameter --name /quasar/api-key --type SecureString --value "qk_live_7d41c9e0b2" >/dev/null

boundary_arn="$(aws_local iam create-policy --policy-name quasar-self-service-boundary \
  --policy-document "file://$MISSION_DIR/workspace/boundary.json" --query Policy.Arn --output text)"

aws_local iam create-role --role-name key-audit-role --permissions-boundary "$boundary_arn" \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null

# What the role policy grants was approved in review; the boundary is what trims it.
aws_local iam put-role-policy --role-name key-audit-role --policy-name audit-job \
  --policy-document '{"Version":"2012-10-17","Statement":[
    {"Effect":"Allow","Action":"ssm:GetParameter","Resource":"arn:aws:ssm:us-east-1:000000000000:parameter/quasar/*"},
    {"Effect":"Allow","Action":"s3:PutObject","Resource":"arn:aws:s3:::quasar-audit-records/fingerprints/*"},
    {"Effect":"Allow","Action":"dynamodb:*","Resource":"*"}]}'

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
(cd "$MISSION_DIR/workspace" && zip -q "$stage/rotator.zip" rotator.py)
aws_local lambda create-function --function-name key-audit \
  --runtime python3.12 --handler rotator.audit \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/key-audit-role" \
  --zip-file "fileb://$stage/rotator.zip" >/dev/null

echo "key-audit has an approved role policy and still gets AccessDenied."
