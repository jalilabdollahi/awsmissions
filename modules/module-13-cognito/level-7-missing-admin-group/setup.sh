#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

POOL_ID="$(aws_local cognito-idp create-user-pool --pool-name parcelpost-staff \
  --query 'UserPool.Id' --output text)"
aws_local cognito-idp create-user-pool-client --user-pool-id "$POOL_ID" --client-name parcelpost-console \
  --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH >/dev/null

for who in dara eli; do
  aws_local cognito-idp admin-create-user --user-pool-id "$POOL_ID" --username "$who" \
    --message-action SUPPRESS --user-attributes "Name=email,Value=$who@example.com" >/dev/null
  aws_local cognito-idp admin-set-user-password --user-pool-id "$POOL_ID" --username "$who" \
    --password 'Parcel-Route-2024!' --permanent
done

# The groups as they exist today. The admin group was created with a slightly different name
# than the one the console looks for.
aws_local cognito-idp create-group --user-pool-id "$POOL_ID" --group-name ops-admin \
  --description "Operations leads" --precedence 1 >/dev/null
aws_local cognito-idp create-group --user-pool-id "$POOL_ID" --group-name support \
  --description "Customer support" --precedence 10 >/dev/null
aws_local cognito-idp admin-add-user-to-group --user-pool-id "$POOL_ID" --username dara --group-name ops-admin
aws_local cognito-idp admin-add-user-to-group --user-pool-id "$POOL_ID" --username eli --group-name support

echo "parcelpost-staff has two users and two groups. The console still sees Dara as read-only."
