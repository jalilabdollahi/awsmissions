#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

POOL_ID="$(aws_local cognito-idp list-user-pools --max-results 60 \
  --query "UserPools[?Name=='skylark-travelers'].Id | [0]" --output text 2>/dev/null || true)"
if [ -z "$POOL_ID" ] || [ "$POOL_ID" = "None" ]; then
  echo "The user pool skylark-travelers no longer exists."
  exit 1
fi
CLIENT_ID="$(aws_local cognito-idp list-user-pool-clients --user-pool-id "$POOL_ID" --max-results 60 \
  --query "UserPoolClients[?ClientName=='skylark-spa'].ClientId | [0]" --output text)"
if [ -z "$CLIENT_ID" ] || [ "$CLIENT_ID" = "None" ]; then
  echo "The client skylark-spa no longer exists. The app is configured with its ID, so it has to be repaired in place."
  exit 1
fi

set +e
out="$(aws_local cognito-idp initiate-auth --client-id "$CLIENT_ID" --auth-flow USER_PASSWORD_AUTH \
  --auth-parameters USERNAME=yuki,PASSWORD='Window-Seat-12A!' --output json 2>&1)"
rc=$?
set -e
if [ "$rc" -ne 0 ]; then
  echo "yuki cannot sign in through skylark-spa."
  echo "Cognito said: $(printf '%s' "$out" | tail -1)"
  echo "Compare the client's current settings with the contract in the briefing."
  exit 1
fi

lifetimes="$(printf '%s' "$out" | python3 -c '
import sys, json, base64
res = json.load(sys.stdin)["AuthenticationResult"]
def life(tok):
    part = tok.split(".")[1]
    part += "=" * (-len(part) % 4)
    c = json.loads(base64.urlsafe_b64decode(part))
    return c["exp"] - c["iat"]
print(life(res["AccessToken"]), life(res["IdToken"]))')"
access_life="${lifetimes% *}"
id_life="${lifetimes#* }"
if [ "$access_life" -ne 1800 ]; then
  echo "The access token lives $access_life seconds; the contract says 30 minutes (1800)."
  exit 1
fi
if [ "$id_life" -ne 1800 ]; then
  echo "The ID token lives $id_life seconds; the contract says 30 minutes (1800)."
  exit 1
fi

refresh="$(printf '%s' "$out" | jq -r '.AuthenticationResult.RefreshToken // empty')"
if [ -z "$refresh" ] || ! aws_local cognito-idp initiate-auth --client-id "$CLIENT_ID" --auth-flow REFRESH_TOKEN_AUTH \
     --auth-parameters REFRESH_TOKEN="$refresh" >/dev/null 2>&1; then
  echo "Sign-in works, but a refresh token cannot be exchanged for new tokens."
  exit 1
fi

cfg="$(aws_local cognito-idp describe-user-pool-client --user-pool-id "$POOL_ID" --client-id "$CLIENT_ID" \
  --query 'UserPoolClient.[RefreshTokenValidity, TokenValidityUnits.RefreshToken]' --output text)"
if [ "$cfg" != "$(printf '14\tdays')" ]; then
  echo "The refresh token validity is currently: $(printf '%s' "$cfg" | tr '\t' ' '). The contract says 14 days."
  exit 1
fi

# The hosted-UI login must be reachable on both callback URLs, and only those.
authorize_status() {
  curl -s -o /dev/null -w '%{http_code}' \
    "$AWS_ENDPOINT_URL/cognito-idp/oauth2/authorize?client_id=$CLIENT_ID&response_type=code&scope=openid&redirect_uri=$1"
}
for url in https://app.example.com/auth/callback https://preview.example.com/cb; do
  status="$(authorize_status "$url")"
  if [ "$status" != "302" ]; then
    echo "The hosted-UI login for $url answers HTTP $status instead of starting a login."
    echo "Check the callback URLs and the OAuth settings on the client."
    exit 1
  fi
done
if [ "$(authorize_status https://evil.example.net/steal)" = "302" ]; then
  echo "The hosted UI accepts an unregistered callback URL."
  exit 1
fi

echo "skylark-spa is back to its contract, and the preview callback survived the repair."
