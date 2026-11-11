#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

POOL_ID="$(aws_local cognito-idp list-user-pools --max-results 60 \
  --query "UserPools[?Name=='marigold-fans'].Id | [0]" --output text 2>/dev/null || true)"
if [ -z "$POOL_ID" ] || [ "$POOL_ID" = "None" ]; then
  echo "The user pool marigold-fans no longer exists."
  exit 1
fi
CLIENT_ID="$(aws_local cognito-idp list-user-pool-clients --user-pool-id "$POOL_ID" --max-results 60 \
  --query "UserPoolClients[?ClientName=='marigold-web'].ClientId | [0]" --output text)"
if [ -z "$CLIENT_ID" ] || [ "$CLIENT_ID" = "None" ]; then
  echo "The client marigold-web no longer exists. The app is configured with its ID."
  exit 1
fi

PROD_URL="https://marigold.example.com/auth/callback"
DEV_URL="http://localhost:3000/callback"
jar="$(mktemp)"
trap 'rm -f "$jar"' EXIT

authorize_url() {  # authorize_url REDIRECT_URI
  printf '%s/cognito-idp/oauth2/authorize?client_id=%s&response_type=code&scope=openid&redirect_uri=%s' \
    "$AWS_ENDPOINT_URL" "$CLIENT_ID" "$(python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' "$1")"
}
authorize_code() {  # authorize_code REDIRECT_URI -> HTTP status of the authorize call
  curl -s -o /dev/null -w '%{http_code}' "$(authorize_url "$1")"
}

# 1. Full login on the production URL.
: > "$jar"
page="$(curl -s -L -c "$jar" -w '\n%{http_code}' "$(authorize_url "$PROD_URL")")"
status="$(printf '%s' "$page" | tail -1)"
if [ "$status" != "200" ]; then
  echo "The hosted UI refuses the production authorize request (HTTP $status)."
  detail="$(curl -s "$(authorize_url "$PROD_URL")" | jq -r '.error_description // empty' 2>/dev/null || true)"
  [ -n "$detail" ] && echo "Cognito said: $detail"
  exit 1
fi
csrf="$(printf '%s' "$page" | sed -n 's/.*name="_csrf" value="\([^"]*\)".*/\1/p' | head -1)"
if [ -z "$csrf" ]; then
  echo "The login page came back without a form token."
  exit 1
fi
headers="$(curl -s -i -b "$jar" -X POST "$AWS_ENDPOINT_URL/cognito-idp/login" \
  --data-urlencode "_csrf=$csrf" -d response_type=code -d "client_id=$CLIENT_ID" -d scope=openid \
  --data-urlencode "redirect_uri=$PROD_URL" -d username=noor --data-urlencode 'password=Front-Row-Seats-3!')"
location="$(printf '%s' "$headers" | tr -d '\r' | sed -n 's/^[Ll]ocation: //p' | head -1)"
case "$location" in
  "$PROD_URL"\?code=*) ;;
  *)
    echo "Signing in as noor did not redirect back to the production URL with a code (got: ${location:-no redirect})."
    exit 1 ;;
esac
code="${location#*code=}"
code="${code%%&*}"
tokens="$(curl -s -X POST "$AWS_ENDPOINT_URL/cognito-idp/oauth2/token" -d grant_type=authorization_code \
  -d "client_id=$CLIENT_ID" -d "code=$code" --data-urlencode "redirect_uri=$PROD_URL")"
id_token="$(printf '%s' "$tokens" | jq -r '.id_token // empty' 2>/dev/null || true)"
if [ -z "$id_token" ]; then
  echo "The code could not be exchanged for tokens: $(printf '%s' "$tokens" | jq -r '.error_description // .error // empty' 2>/dev/null)"
  exit 1
fi
claims="$(printf '%s' "$id_token" | python3 -c '
import sys, json, base64
part = sys.stdin.read().strip().split(".")[1]
part += "=" * (-len(part) % 4)
c = json.loads(base64.urlsafe_b64decode(part))
print(c.get("aud", ""), c.get("cognito:username", ""))')"
if [ "$claims" != "$CLIENT_ID noor" ]; then
  echo "The ID token does not belong to noor on marigold-web ($claims)."
  exit 1
fi

# 2. The developers' localhost callback still works.
if [ "$(authorize_code "$DEV_URL")" != "200" ] && [ "$(authorize_code "$DEV_URL")" != "302" ]; then
  echo "The localhost callback was removed. The front-end team still develops against it."
  exit 1
fi

# 3. Nothing else is accepted.
for bad in "https://marigold.example.com/auth/callback/" "https://marigold.example.com/" "https://evil.example.net/auth/callback" "http://marigold.example.com/auth/callback"; do
  if [ "$(authorize_code "$bad")" != "400" ]; then
    echo "The callback URL $bad is accepted. Register exactly the URLs the apps use, nothing broader or lookalike."
    exit 1
  fi
done

# 4. No implicit flow left behind.
flows="$(aws_local cognito-idp describe-user-pool-client --user-pool-id "$POOL_ID" --client-id "$CLIENT_ID" \
  --query 'UserPoolClient.AllowedOAuthFlows' --output text)"
case "$flows" in
  *implicit*)
    echo "The implicit flow is still enabled on the client. It returns tokens in the URL and is deprecated; the app uses the code flow."
    exit 1 ;;
esac

echo "The hosted login works end to end for production and localhost, and nothing else gets through."
