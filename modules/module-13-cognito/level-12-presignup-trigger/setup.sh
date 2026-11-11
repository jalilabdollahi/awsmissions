#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local iam create-role --role-name brightpath-presignup-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null

build="$(mktemp -d)"
trap 'rm -rf "$build"' EXIT
cp "$MISSION_DIR/workspace/presignup.py" "$build/presignup.py"
(cd "$build" && zip -q function.zip presignup.py)

FUNCTION_ARN="$(aws_local lambda create-function --function-name brightpath-presignup \
  --runtime python3.12 --handler presignup.handler \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/brightpath-presignup-role" \
  --zip-file "fileb://$build/function.zip" --query FunctionArn --output text)"

POOL_ID="$(aws_local cognito-idp create-user-pool --pool-name brightpath-partners \
  --lambda-config "PreSignUp=$FUNCTION_ARN" --query 'UserPool.Id' --output text)"
aws_local lambda add-permission --function-name brightpath-presignup --statement-id cognito-invoke \
  --action lambda:InvokeFunction --principal cognito-idp.amazonaws.com \
  --source-arn "arn:aws:cognito-idp:us-east-1:${ACCOUNT_ID}:userpool/${POOL_ID}" >/dev/null

aws_local cognito-idp create-user-pool-client --user-pool-id "$POOL_ID" --client-name brightpath-portal \
  --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH >/dev/null

echo "brightpath-partners is live with its pre sign-up trigger. Partner registrations are failing."
