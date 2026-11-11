#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

POOL_ID="$(aws_local cognito-idp create-user-pool --pool-name brewline-customers \
  --query 'UserPool.Id' --output text)"

# The v3 app talks USER_PASSWORD_AUTH, but the client was created for the
# web dashboard: SRP and refresh only.
aws_local cognito-idp create-user-pool-client --user-pool-id "$POOL_ID" \
  --client-name brewline-app \
  --explicit-auth-flows ALLOW_USER_SRP_AUTH ALLOW_REFRESH_TOKEN_AUTH >/dev/null

aws_local cognito-idp admin-create-user --user-pool-id "$POOL_ID" --username nora \
  --message-action SUPPRESS \
  --user-attributes Name=email,Value=nora@example.com Name=email_verified,Value=true >/dev/null
aws_local cognito-idp admin-set-user-password --user-pool-id "$POOL_ID" --username nora \
  --password 'Latte-Art-2024!' --permanent

echo "brewline-customers is up. Version 3 of the app cannot sign anyone in."
