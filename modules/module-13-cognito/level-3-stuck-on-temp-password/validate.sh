#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

POOL_ID="$(aws_local cognito-idp list-user-pools --max-results 60 \
  --query "UserPools[?Name=='lumen-dispatch'].Id | [0]" --output text 2>/dev/null || true)"
if [ -z "$POOL_ID" ] || [ "$POOL_ID" = "None" ]; then
  echo "The user pool lumen-dispatch no longer exists."
  exit 1
fi
CLIENT_ID="$(aws_local cognito-idp list-user-pool-clients --user-pool-id "$POOL_ID" --max-results 60 \
  --query "UserPoolClients[?ClientName=='lumen-portal'].ClientId | [0]" --output text)"
if [ -z "$CLIENT_ID" ] || [ "$CLIENT_ID" = "None" ]; then
  echo "The app client lumen-portal no longer exists."
  exit 1
fi

signin() {
  aws_local cognito-idp initiate-auth --client-id "$CLIENT_ID" --auth-flow USER_PASSWORD_AUTH \
    --auth-parameters "USERNAME=$1,PASSWORD=$2" --output json 2>&1
}

set +e
tomas_out="$(signin tomas 'Pallet-Jack-2024!')"
tomas_rc=$?
ines_out="$(signin ines 'Harbor-Crane-81x')"
ines_rc=$?
set -e

if [ "$tomas_rc" -ne 0 ] || [ -z "$(printf '%s' "$tomas_out" | jq -r '.AuthenticationResult.IdToken // empty' 2>/dev/null)" ]; then
  echo "Tomas can no longer sign in with his own password. Do not disturb accounts that work."
  exit 1
fi

if [ "$ines_rc" -ne 0 ]; then
  echo "Ines cannot sign in with Harbor-Crane-81x."
  echo "Cognito said: $(printf '%s' "$ines_out" | tail -1)"
  exit 1
fi

challenge="$(printf '%s' "$ines_out" | jq -r '.ChallengeName // empty')"
if [ -n "$challenge" ]; then
  echo "Ines's sign-in still ends in a challenge ($challenge) instead of tokens, and the portal cannot answer challenges."
  echo "Check what state her account is in."
  exit 1
fi

id_token="$(printf '%s' "$ines_out" | jq -r '.AuthenticationResult.IdToken // empty')"
who="$(printf '%s' "$id_token" | python3 -c '
import sys, json, base64
part = sys.stdin.read().strip().split(".")[1]
part += "=" * (-len(part) % 4)
print(json.loads(base64.urlsafe_b64decode(part)).get("cognito:username", ""))')"
if [ "$who" != "ines" ]; then
  echo "The tokens do not belong to ines."
  exit 1
fi

status="$(aws_local cognito-idp admin-get-user --user-pool-id "$POOL_ID" --username ines \
  --query UserStatus --output text)"
if [ "$status" != "CONFIRMED" ]; then
  echo "Ines gets tokens but her account status is $status, not CONFIRMED."
  exit 1
fi

echo "Ines is confirmed and signs in with her new password. Welcome aboard."
