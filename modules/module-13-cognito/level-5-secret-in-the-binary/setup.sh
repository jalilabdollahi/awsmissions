#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

POOL_ID="$(aws_local cognito-idp create-user-pool --pool-name quill-accounts \
  --query 'UserPool.Id' --output text)"

# The backend's confidential client: it holds a secret.
aws_local cognito-idp create-user-pool-client --user-pool-id "$POOL_ID" --client-name quill-web \
  --generate-secret \
  --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH >/dev/null

aws_local cognito-idp admin-create-user --user-pool-id "$POOL_ID" --username mira \
  --message-action SUPPRESS --user-attributes Name=email,Value=mira@example.com >/dev/null
aws_local cognito-idp admin-set-user-password --user-pool-id "$POOL_ID" --username mira \
  --password 'Margin-Notes-55!' --permanent

echo "quill-accounts has a backend client with a secret. The mobile app has nothing it may use."
