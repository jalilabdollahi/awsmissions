#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

POOL_ID="$(aws_local cognito-idp create-user-pool --pool-name kestrel-members \
  --auto-verified-attributes email --query 'UserPool.Id' --output text)"
CLIENT_ID="$(aws_local cognito-idp create-user-pool-client --user-pool-id "$POOL_ID" \
  --client-name kestrel-ios \
  --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH \
  --query 'UserPoolClient.ClientId' --output text)"

# Kai registered through the public sign-up call and never confirmed.
aws_local cognito-idp sign-up --client-id "$CLIENT_ID" --username kai \
  --password 'Sprint-Interval-9!' --user-attributes Name=email,Value=kai@example.com >/dev/null

echo "kai has signed up but is stuck in UNCONFIRMED."
