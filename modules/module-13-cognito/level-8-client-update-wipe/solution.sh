#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

POOL_ID="$(aws_local cognito-idp list-user-pools --max-results 60 \
  --query "UserPools[?Name=='skylark-travelers'].Id | [0]" --output text)"
CLIENT_ID="$(aws_local cognito-idp list-user-pool-clients --user-pool-id "$POOL_ID" \
  --query "UserPoolClients[?ClientName=='skylark-spa'].ClientId | [0]" --output text)"

# One complete update that carries every setting.
aws_local cognito-idp update-user-pool-client --user-pool-id "$POOL_ID" --client-id "$CLIENT_ID" \
  --client-name skylark-spa \
  --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH \
  --access-token-validity 30 --id-token-validity 30 --refresh-token-validity 14 \
  --token-validity-units AccessToken=minutes,IdToken=minutes,RefreshToken=days \
  --callback-urls https://app.example.com/auth/callback https://preview.example.com/cb \
  --logout-urls https://app.example.com/signed-out \
  --allowed-o-auth-flows code --allowed-o-auth-scopes openid email profile \
  --allowed-o-auth-flows-user-pool-client --supported-identity-providers COGNITO >/dev/null
