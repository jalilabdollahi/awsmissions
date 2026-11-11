#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

POOL_ID="$(aws_local cognito-idp create-user-pool --pool-name tidewater-readers \
  --policies 'PasswordPolicy={MinimumLength=24,RequireUppercase=true,RequireLowercase=true,RequireNumbers=true,RequireSymbols=true,TemporaryPasswordValidityDays=7}' \
  --query 'UserPool.Id' --output text)"

aws_local cognito-idp create-user-pool-client --user-pool-id "$POOL_ID" \
  --client-name tidewater-web \
  --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH >/dev/null

echo "tidewater-readers is open for sign-ups and nobody can get through."
