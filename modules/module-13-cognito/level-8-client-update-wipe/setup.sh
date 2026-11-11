#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

POOL_ID="$(aws_local cognito-idp create-user-pool --pool-name skylark-travelers \
  --query 'UserPool.Id' --output text)"

# The client as the app team configured it.
CLIENT_ID="$(aws_local cognito-idp create-user-pool-client --user-pool-id "$POOL_ID" \
  --client-name skylark-spa \
  --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH \
  --access-token-validity 30 --id-token-validity 30 --refresh-token-validity 14 \
  --token-validity-units AccessToken=minutes,IdToken=minutes,RefreshToken=days \
  --callback-urls https://app.example.com/auth/callback \
  --logout-urls https://app.example.com/signed-out \
  --allowed-o-auth-flows code --allowed-o-auth-scopes openid email profile \
  --allowed-o-auth-flows-user-pool-client --supported-identity-providers COGNITO \
  --query 'UserPoolClient.ClientId' --output text)"

aws_local cognito-idp admin-create-user --user-pool-id "$POOL_ID" --username yuki \
  --message-action SUPPRESS --user-attributes Name=email,Value=yuki@example.com >/dev/null
aws_local cognito-idp admin-set-user-password --user-pool-id "$POOL_ID" --username yuki \
  --password 'Window-Seat-12A!' --permanent

# Yesterday's "small" change: update-user-pool-client replaces everything that is not passed.
aws_local cognito-idp update-user-pool-client --user-pool-id "$POOL_ID" --client-id "$CLIENT_ID" \
  --client-name skylark-spa \
  --callback-urls https://app.example.com/auth/callback https://preview.example.com/cb \
  --logout-urls https://app.example.com/signed-out \
  --allowed-o-auth-flows code --allowed-o-auth-scopes openid email profile \
  --allowed-o-auth-flows-user-pool-client --supported-identity-providers COGNITO >/dev/null

echo "skylark-spa had its callback URL added. Sign-in has been broken since."
