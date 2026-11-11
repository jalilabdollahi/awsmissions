#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

POOL_ID="$(aws_local cognito-idp create-user-pool --pool-name lumen-dispatch \
  --query 'UserPool.Id' --output text)"
aws_local cognito-idp create-user-pool-client --user-pool-id "$POOL_ID" --client-name lumen-portal \
  --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH >/dev/null

# Tomas has been around for a month and is fully set up.
aws_local cognito-idp admin-create-user --user-pool-id "$POOL_ID" --username tomas \
  --message-action SUPPRESS --user-attributes Name=email,Value=tomas@example.com >/dev/null
aws_local cognito-idp admin-set-user-password --user-pool-id "$POOL_ID" --username tomas \
  --password 'Pallet-Jack-2024!' --permanent

# Ines was created on Monday with a temporary password and never changed it.
aws_local cognito-idp admin-create-user --user-pool-id "$POOL_ID" --username ines \
  --temporary-password 'Temp-Welcome-0001!' --message-action SUPPRESS \
  --user-attributes Name=email,Value=ines@example.com >/dev/null

echo "lumen-dispatch has Tomas (active) and Ines (just onboarded, stuck)."
