#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

POOL_ID="$(aws_local cognito-idp list-user-pools --max-results 60 \
  --query "UserPools[?Name=='pinecrest-patrons'].Id | [0]" --output text 2>/dev/null || true)"
if [ -z "$POOL_ID" ] || [ "$POOL_ID" = "None" ]; then
  echo "The user pool pinecrest-patrons no longer exists."
  exit 1
fi
CLIENT_ID="$(aws_local cognito-idp list-user-pool-clients --user-pool-id "$POOL_ID" --max-results 60 \
  --query "UserPoolClients[?ClientName=='pinecrest-portal'].ClientId | [0]" --output text)"
if [ -z "$CLIENT_ID" ] || [ "$CLIENT_ID" = "None" ]; then
  echo "The app client pinecrest-portal no longer exists."
  exit 1
fi

# Lena must be untouched.
lena_email="$(aws_local cognito-idp admin-get-user --user-pool-id "$POOL_ID" --username lena \
  --query "UserAttributes[?Name=='email'].Value | [0]" --output text 2>/dev/null || true)"
if [ "$lena_email" != "lena@example.com" ]; then
  echo "Lena's record was changed. Only Omar's account needs work."
  exit 1
fi

before="$(curl -s "$AWS_ENDPOINT_URL/_aws/ses" | jq '.messages | length')"

set +e
out="$(aws_local cognito-idp forgot-password --client-id "$CLIENT_ID" --username omar 2>&1)"
rc=$?
set -e
if [ "$rc" -ne 0 ]; then
  echo "Starting a password reset for omar still fails."
  echo "Cognito said: $(printf '%s' "$out" | tail -1)"
  exit 1
fi

# Where did the code actually go?
mail="$(curl -s "$AWS_ENDPOINT_URL/_aws/ses")"
after="$(printf '%s' "$mail" | jq '.messages | length')"
if [ "$after" -le "$before" ]; then
  echo "Cognito accepted the reset request but no email was sent."
  exit 1
fi
to="$(printf '%s' "$mail" | jq -r '.messages | last | .Destination.ToAddresses[0]')"
if [ "$to" != "omar@example.com" ]; then
  echo "The reset code was sent to $to, not to omar@example.com. Patrons only receive codes at the address the library has on record."
  exit 1
fi
code="$(printf '%s' "$mail" | jq -r '.messages | last | .Body.text_part' | grep -o '[0-9]\{6\}' | head -1)"
if [ -z "$code" ]; then
  echo "The email did not contain a code."
  exit 1
fi

set +e
out="$(aws_local cognito-idp confirm-forgot-password --client-id "$CLIENT_ID" --username omar \
  --confirmation-code "$code" --password 'Reset-Check-4711!' 2>&1)"
rc=$?
set -e
if [ "$rc" -ne 0 ]; then
  echo "The reset code could not be redeemed: $(printf '%s' "$out" | tail -1)"
  exit 1
fi
if ! aws_local cognito-idp initiate-auth --client-id "$CLIENT_ID" --auth-flow USER_PASSWORD_AUTH \
     --auth-parameters USERNAME=omar,PASSWORD='Reset-Check-4711!' --query 'AuthenticationResult.AccessToken' \
     --output text >/dev/null 2>&1; then
  echo "The reset completed but omar cannot sign in with the new password."
  exit 1
fi

echo "A reset code reached omar@example.com, redeemed it, and Omar signed in with the new password."
