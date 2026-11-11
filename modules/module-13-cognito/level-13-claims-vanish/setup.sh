#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local iam create-role --role-name cobalt-triggers-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/cobalt-triggers-role"

build="$(mktemp -d)"
trap 'rm -rf "$build"' EXIT
cp "$MISSION_DIR/workspace/claims.py" "$MISSION_DIR/workspace/welcome.py" "$build/"
(cd "$build" && zip -q claims.zip claims.py && zip -q welcome.zip welcome.py)

CLAIMS_ARN="$(aws_local lambda create-function --function-name cobalt-claims --runtime python3.12 \
  --handler claims.handler --role "$ROLE_ARN" --zip-file "fileb://$build/claims.zip" \
  --query FunctionArn --output text)"
WELCOME_ARN="$(aws_local lambda create-function --function-name cobalt-welcome --runtime python3.12 \
  --handler welcome.handler --role "$ROLE_ARN" --zip-file "fileb://$build/welcome.zip" \
  --query FunctionArn --output text)"

POOL_ID="$(aws_local cognito-idp create-user-pool --pool-name cobalt-tenants \
  --policies 'PasswordPolicy={MinimumLength=10,RequireUppercase=true,RequireLowercase=true,RequireNumbers=true,RequireSymbols=false}' \
  --schema Name=tenant,AttributeDataType=String,Mutable=true \
  --lambda-config "PreTokenGeneration=$CLAIMS_ARN" \
  --query 'UserPool.Id' --output text)"
for fn in cobalt-claims cobalt-welcome; do
  aws_local lambda add-permission --function-name "$fn" --statement-id cognito-invoke \
    --action lambda:InvokeFunction --principal cognito-idp.amazonaws.com \
    --source-arn "arn:aws:cognito-idp:us-east-1:${ACCOUNT_ID}:userpool/${POOL_ID}" >/dev/null
done

aws_local cognito-idp create-user-pool-client --user-pool-id "$POOL_ID" --client-name cobalt-app \
  --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH >/dev/null

for pair in ava:acme ben:globex; do
  who="${pair%%:*}"
  tenant="${pair##*:}"
  aws_local cognito-idp admin-create-user --user-pool-id "$POOL_ID" --username "$who" \
    --message-action SUPPRESS \
    --user-attributes "Name=email,Value=$who@example.com" "Name=custom:tenant,Value=$tenant" >/dev/null
  aws_local cognito-idp admin-set-user-password --user-pool-id "$POOL_ID" --username "$who" \
    --password 'Tenant-Wall-2024!' --permanent
done

# Yesterday's change: attach the welcome function. update-user-pool replaces the whole LambdaConfig.
aws_local cognito-idp update-user-pool --user-pool-id "$POOL_ID" \
  --lambda-config "PostConfirmation=$WELCOME_ARN"

echo "cobalt-tenants is live. Tokens come out without a tenant claim."
