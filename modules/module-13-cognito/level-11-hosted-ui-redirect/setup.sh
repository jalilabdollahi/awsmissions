#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

POOL_ID="$(aws_local cognito-idp create-user-pool --pool-name marigold-fans \
  --query 'UserPool.Id' --output text)"

# Created a long time ago for a prototype: implicit flow, and a callback that no longer matches the app.
aws_local cognito-idp create-user-pool-client --user-pool-id "$POOL_ID" --client-name marigold-web \
  --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH \
  --callback-urls "https://marigold.example.com/auth/callback/" "http://localhost:3000/callback" \
  --allowed-o-auth-flows implicit --allowed-o-auth-scopes openid email \
  --allowed-o-auth-flows-user-pool-client --supported-identity-providers COGNITO >/dev/null

aws_local cognito-idp admin-create-user --user-pool-id "$POOL_ID" --username noor \
  --message-action SUPPRESS --user-attributes Name=email,Value=noor@example.com >/dev/null
aws_local cognito-idp admin-set-user-password --user-pool-id "$POOL_ID" --username noor \
  --password 'Front-Row-Seats-3!' --permanent

echo "marigold-fans is up. The hosted login rejects the production app."
