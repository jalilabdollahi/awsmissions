#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

POOL_ID="$(aws_local cognito-idp list-user-pools --max-results 60 \
  --query "UserPools[?Name=='marigold-fans'].Id | [0]" --output text)"
CLIENT_ID="$(aws_local cognito-idp list-user-pool-clients --user-pool-id "$POOL_ID" \
  --query "UserPoolClients[?ClientName=='marigold-web'].ClientId | [0]" --output text)"

aws_local cognito-idp update-user-pool-client --user-pool-id "$POOL_ID" --client-id "$CLIENT_ID" \
  --client-name marigold-web \
  --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH \
  --callback-urls "https://marigold.example.com/auth/callback" "http://localhost:3000/callback" \
  --allowed-o-auth-flows code --allowed-o-auth-scopes openid email \
  --allowed-o-auth-flows-user-pool-client --supported-identity-providers COGNITO >/dev/null
