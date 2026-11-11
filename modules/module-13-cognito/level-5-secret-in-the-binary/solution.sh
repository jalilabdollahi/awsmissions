#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

POOL_ID="$(aws_local cognito-idp list-user-pools --max-results 60 \
  --query "UserPools[?Name=='quill-accounts'].Id | [0]" --output text)"

# A client secret cannot be removed from an existing client, so make a new client without one.
aws_local cognito-idp create-user-pool-client --user-pool-id "$POOL_ID" --client-name quill-mobile \
  --no-generate-secret \
  --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH >/dev/null
