#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# 1. Take the IAM write actions out of the role (paths 1, 3 and 4).
# 2. Scope Lambda and PassRole to qf-* functions and the standard execution role (path 2).
aws_local iam put-role-policy --role-name qf-ci-deployer --policy-name ci-deploy --policy-document '{
  "Version":"2012-10-17","Statement":[
   {"Sid":"Lambda","Effect":"Allow","Action":["lambda:CreateFunction","lambda:UpdateFunctionCode","lambda:UpdateFunctionConfiguration","lambda:GetFunction"],"Resource":"arn:aws:lambda:us-east-1:000000000000:function:qf-*"},
   {"Sid":"PassStandardRoleOnly","Effect":"Allow","Action":"iam:PassRole","Resource":"arn:aws:iam::000000000000:role/qf-svc-lambda-exec"},
   {"Sid":"Artifacts","Effect":"Allow","Action":["s3:PutObject","s3:GetObject"],"Resource":"arn:aws:s3:::qf-build-artifacts/*"}]}'
