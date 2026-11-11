#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

POOL_ID="$(aws_local cognito-idp list-user-pools --max-results 60 \
  --query "UserPools[?Name=='quill-accounts'].Id | [0]" --output text 2>/dev/null || true)"
if [ -z "$POOL_ID" ] || [ "$POOL_ID" = "None" ]; then
  echo "The user pool quill-accounts no longer exists."
  exit 1
fi
client_id() {
  aws_local cognito-idp list-user-pool-clients --user-pool-id "$POOL_ID" --max-results 60 \
    --query "UserPoolClients[?ClientName=='$1'].ClientId | [0]" --output text
}
WEB_ID="$(client_id quill-web)"
MOBILE_ID="$(client_id quill-mobile)"

# The backend client must be intact: secret still required and still working.
if [ -z "$WEB_ID" ] || [ "$WEB_ID" = "None" ]; then
  echo "quill-web is gone. The backend still depends on it; it must keep working."
  exit 1
fi
SECRET="$(aws_local cognito-idp describe-user-pool-client --user-pool-id "$POOL_ID" --client-id "$WEB_ID" \
  --query 'UserPoolClient.ClientSecret' --output text)"
if [ -z "$SECRET" ] || [ "$SECRET" = "None" ]; then
  echo "quill-web no longer has a client secret. It was fine as it was; leave the backend client alone."
  exit 1
fi
HASH="$(python3 -c '
import sys, hmac, hashlib, base64
secret, user, client = sys.argv[1:4]
print(base64.b64encode(hmac.new(secret.encode(), (user + client).encode(), hashlib.sha256).digest()).decode())
' "$SECRET" mira "$WEB_ID")"
if ! aws_local cognito-idp initiate-auth --client-id "$WEB_ID" --auth-flow USER_PASSWORD_AUTH \
     --auth-parameters "USERNAME=mira,PASSWORD=Margin-Notes-55!,SECRET_HASH=$HASH" >/dev/null 2>&1; then
  echo "The backend can no longer sign mira in through quill-web with its SECRET_HASH. Do not change that client."
  exit 1
fi

if [ -z "$MOBILE_ID" ] || [ "$MOBILE_ID" = "None" ]; then
  echo "There is no app client named quill-mobile yet."
  exit 1
fi
mobile_secret="$(aws_local cognito-idp describe-user-pool-client --user-pool-id "$POOL_ID" --client-id "$MOBILE_ID" \
  --query 'UserPoolClient.ClientSecret' --output text)"
if [ -n "$mobile_secret" ] && [ "$mobile_secret" != "None" ]; then
  echo "quill-mobile has a client secret. A secret inside a downloadable app is not a secret, so the mobile client must not have one."
  exit 1
fi

set +e
out="$(aws_local cognito-idp initiate-auth --client-id "$MOBILE_ID" --auth-flow USER_PASSWORD_AUTH \
  --auth-parameters USERNAME=mira,PASSWORD='Margin-Notes-55!' --output json 2>&1)"
rc=$?
set -e
if [ "$rc" -ne 0 ]; then
  echo "mira cannot sign in through quill-mobile."
  echo "Cognito said: $(printf '%s' "$out" | tail -1)"
  exit 1
fi
refresh="$(printf '%s' "$out" | jq -r '.AuthenticationResult.RefreshToken // empty')"
access="$(printf '%s' "$out" | jq -r '.AuthenticationResult.AccessToken // empty')"
if [ -z "$access" ]; then
  echo "Sign-in through quill-mobile returned no tokens."
  exit 1
fi
cid="$(printf '%s' "$access" | python3 -c '
import sys, json, base64
part = sys.stdin.read().strip().split(".")[1]
part += "=" * (-len(part) % 4)
print(json.loads(base64.urlsafe_b64decode(part)).get("client_id", ""))')"
if [ "$cid" != "$MOBILE_ID" ]; then
  echo "The access token was not issued for quill-mobile."
  exit 1
fi
if [ -z "$refresh" ] || ! aws_local cognito-idp initiate-auth --client-id "$MOBILE_ID" --auth-flow REFRESH_TOKEN_AUTH \
     --auth-parameters REFRESH_TOKEN="$refresh" >/dev/null 2>&1; then
  echo "Sign-in works but refreshing the session through quill-mobile does not. Phones need to stay signed in."
  exit 1
fi

echo "quill-mobile signs mira in and refreshes with no secret, and quill-web still serves the backend."
