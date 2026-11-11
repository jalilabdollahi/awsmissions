#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

POOL_ID="$(aws_local cognito-idp list-user-pools --max-results 60 \
  --query "UserPools[?Name=='kestrel-members'].Id | [0]" --output text 2>/dev/null || true)"
if [ -z "$POOL_ID" ] || [ "$POOL_ID" = "None" ]; then
  echo "The user pool kestrel-members no longer exists."
  exit 1
fi
CLIENT_ID="$(aws_local cognito-idp list-user-pool-clients --user-pool-id "$POOL_ID" --max-results 60 \
  --query "UserPoolClients[?ClientName=='kestrel-ios'].ClientId | [0]" --output text)"
if [ -z "$CLIENT_ID" ] || [ "$CLIENT_ID" = "None" ]; then
  echo "The app client kestrel-ios no longer exists."
  exit 1
fi

set +e
out="$(aws_local cognito-idp initiate-auth --client-id "$CLIENT_ID" --auth-flow USER_PASSWORD_AUTH \
  --auth-parameters USERNAME=kai,PASSWORD='Sprint-Interval-9!' --output json 2>&1)"
rc=$?
set -e
if [ "$rc" -ne 0 ]; then
  echo "kai still cannot sign in with the password chosen at sign-up."
  echo "Cognito said: $(printf '%s' "$out" | tail -1)"
  exit 1
fi
if [ -z "$(printf '%s' "$out" | jq -r '.AuthenticationResult.AccessToken // empty')" ]; then
  echo "Sign-in did not return tokens."
  exit 1
fi

verified="$(aws_local cognito-idp admin-get-user --user-pool-id "$POOL_ID" --username kai \
  --query "UserAttributes[?Name=='email_verified'].Value | [0]" --output text)"
if [ "$verified" != "true" ]; then
  echo "kai can sign in, but the email address is not marked as verified. The 'forgot password' flow would not work for Kai."
  exit 1
fi

# Behaviour: password reset must be deliverable now.
set +e
reset="$(aws_local cognito-idp forgot-password --client-id "$CLIENT_ID" --username kai 2>&1)"
rc=$?
set -e
if [ "$rc" -ne 0 ]; then
  echo "Starting a password reset for kai fails: $(printf '%s' "$reset" | tail -1)"
  exit 1
fi

echo "kai is confirmed, signs in, and has a verified email. Password resets will reach the inbox."
