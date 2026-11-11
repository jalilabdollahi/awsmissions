#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

POOL_ID="$(aws_local cognito-idp list-user-pools --max-results 60 \
  --query "UserPools[?Name=='brewline-customers'].Id | [0]" --output text 2>/dev/null || true)"
if [ -z "$POOL_ID" ] || [ "$POOL_ID" = "None" ]; then
  echo "The user pool brewline-customers is gone. Fix the existing one instead of deleting it."
  exit 1
fi
CLIENT_ID="$(aws_local cognito-idp list-user-pool-clients --user-pool-id "$POOL_ID" --max-results 60 \
  --query "UserPoolClients[?ClientName=='brewline-app'].ClientId | [0]" --output text)"
if [ -z "$CLIENT_ID" ] || [ "$CLIENT_ID" = "None" ]; then
  echo "The app client brewline-app no longer exists, so the app has nothing to sign in against."
  exit 1
fi

set +e
out="$(aws_local cognito-idp initiate-auth --client-id "$CLIENT_ID" --auth-flow USER_PASSWORD_AUTH \
  --auth-parameters USERNAME=nora,PASSWORD='Latte-Art-2024!' --output json 2>&1)"
rc=$?
set -e
if [ "$rc" -ne 0 ]; then
  echo "nora still cannot sign in with the username-and-password flow."
  echo "Cognito said: $(printf '%s' "$out" | tail -1)"
  exit 1
fi

id_token="$(printf '%s' "$out" | jq -r '.AuthenticationResult.IdToken // empty')"
refresh="$(printf '%s' "$out" | jq -r '.AuthenticationResult.RefreshToken // empty')"
if [ -z "$id_token" ] || [ -z "$refresh" ]; then
  echo "Sign-in answered, but without an ID token and a refresh token."
  exit 1
fi
aud="$(printf '%s' "$id_token" | python3 -c '
import sys, json, base64
part = sys.stdin.read().strip().split(".")[1]
part += "=" * (-len(part) % 4)
print(json.loads(base64.urlsafe_b64decode(part)).get("aud", ""))')"
if [ "$aud" != "$CLIENT_ID" ]; then
  echo "The ID token was not issued for the brewline-app client."
  exit 1
fi

# Refresh must still work: the app keeps customers signed in with it.
if ! aws_local cognito-idp initiate-auth --client-id "$CLIENT_ID" --auth-flow REFRESH_TOKEN_AUTH \
     --auth-parameters REFRESH_TOKEN="$refresh" >/dev/null 2>&1; then
  echo "Sign-in works, but the refresh token no longer does. Customers would be logged out after an hour. Keep the flows the client already had."
  exit 1
fi

flows="$(aws_local cognito-idp describe-user-pool-client --user-pool-id "$POOL_ID" --client-id "$CLIENT_ID" \
  --query 'UserPoolClient.ExplicitAuthFlows' --output text | tr '\t' '\n')"
if ! printf '%s\n' "$flows" | grep -qx 'ALLOW_USER_SRP_AUTH'; then
  echo "The web dashboard signs in with SRP and that flow was removed from the client. Add the new flow without dropping the old ones."
  exit 1
fi
if printf '%s\n' "$flows" | grep -q 'ALLOW_ADMIN_USER_PASSWORD_AUTH'; then
  echo "ALLOW_ADMIN_USER_PASSWORD_AUTH is a server-side flow that needs IAM credentials; a mobile client has no use for it. Remove it."
  exit 1
fi

echo "nora signs in on the brewline-app client, tokens refresh, and SRP is untouched. Coffee is flowing again."
