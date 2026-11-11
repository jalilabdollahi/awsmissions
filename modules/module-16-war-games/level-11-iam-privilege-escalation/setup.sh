#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

A="arn:aws:iam::${ACCOUNT_ID}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
LAMBDA_TRUST='{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}'

aws_local s3 mb s3://qf-build-artifacts >/dev/null
aws_local iam create-user --user-name qf-platform-admin >/dev/null
aws_local iam attach-user-policy --user-name qf-platform-admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

aws_local iam create-role --role-name qf-svc-lambda-exec --assume-role-policy-document "$LAMBDA_TRUST" >/dev/null
aws_local iam create-role --role-name qf-platform-admin-role --assume-role-policy-document "$LAMBDA_TRUST" >/dev/null
aws_local iam attach-role-policy --role-name qf-platform-admin-role --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

printf 'def handler(e, c):\n    return {"v": 1}\n' > "$tmp/app.py"
python3 -c "import zipfile,sys; zipfile.ZipFile(sys.argv[1],'w').write(sys.argv[2],'app.py')" "$tmp/app.zip" "$tmp/app.py"
aws_local lambda create-function --function-name qf-payments-api --runtime python3.12 --handler app.handler \
  --role "$A:role/qf-svc-lambda-exec" --zip-file "fileb://$tmp/app.zip" >/dev/null

aws_local iam create-user --user-name qf-ci-bot >/dev/null
aws_local iam put-user-policy --user-name qf-ci-bot --policy-name assume-deployer --policy-document \
  "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Resource\":\"$A:role/qf-ci-deployer\"}]}"
aws_local iam create-role --role-name qf-ci-deployer --assume-role-policy-document \
  "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"$A:user/qf-ci-bot\"},\"Action\":\"sts:AssumeRole\"}]}" >/dev/null

# "Give the pipeline whatever it asks for" (2024).
aws_local iam put-role-policy --role-name qf-ci-deployer --policy-name ci-deploy --policy-document '{
  "Version":"2012-10-17","Statement":[
   {"Sid":"Lambda","Effect":"Allow","Action":["lambda:CreateFunction","lambda:UpdateFunctionCode","lambda:UpdateFunctionConfiguration","lambda:GetFunction"],"Resource":"*"},
   {"Sid":"Pass","Effect":"Allow","Action":"iam:PassRole","Resource":"*"},
   {"Sid":"Roles","Effect":"Allow","Action":["iam:CreateRole","iam:AttachRolePolicy","iam:PutRolePolicy"],"Resource":"*"},
   {"Sid":"Keys","Effect":"Allow","Action":["iam:CreateAccessKey","iam:ListUsers"],"Resource":"*"},
   {"Sid":"Artifacts","Effect":"Allow","Action":["s3:PutObject","s3:GetObject"],"Resource":"arn:aws:s3:::qf-build-artifacts/*"}]}'

echo "PT-2026-014 is open: the CI role is a skeleton key."
