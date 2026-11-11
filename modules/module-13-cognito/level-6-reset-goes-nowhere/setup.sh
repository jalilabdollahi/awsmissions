#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

POOL_ID="$(aws_local cognito-idp create-user-pool --pool-name pinecrest-patrons \
  --auto-verified-attributes email --query 'UserPool.Id' --output text)"
aws_local cognito-idp create-user-pool-client --user-pool-id "$POOL_ID" --client-name pinecrest-portal \
  --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH >/dev/null

# Lena registered herself: verified address.
aws_local cognito-idp admin-create-user --user-pool-id "$POOL_ID" --username lena \
  --message-action SUPPRESS \
  --user-attributes Name=email,Value=lena@example.com Name=email_verified,Value=true >/dev/null
aws_local cognito-idp admin-set-user-password --user-pool-id "$POOL_ID" --username lena \
  --password 'Shelf-Life-2024!' --permanent

# Omar came in with the bulk import: a mistyped address and no verification.
aws_local cognito-idp admin-create-user --user-pool-id "$POOL_ID" --username omar \
  --message-action SUPPRESS --user-attributes Name=email,Value=omar@exmaple.com >/dev/null
aws_local cognito-idp admin-set-user-password --user-pool-id "$POOL_ID" --username omar \
  --password 'Dewey-Decimal-7!' --permanent

echo "pinecrest-patrons is ready. Omar's password reset is broken."
