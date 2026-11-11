#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

POOL_ID="$(aws_local cognito-idp list-user-pools --max-results 60 \
  --query "UserPools[?Name=='stockroom-machines'].Id | [0]" --output text 2>/dev/null || true)"
if [ -z "$POOL_ID" ] || [ "$POOL_ID" = "None" ]; then
  echo "The user pool stockroom-machines no longer exists."
  exit 1
fi
client_id() {
  aws_local cognito-idp list-user-pool-clients --user-pool-id "$POOL_ID" --max-results 60 \
    --query "UserPoolClients[?ClientName=='$1'].ClientId | [0]" --output text
}
SYNC_ID="$(client_id nightly-sync)"
DASH_ID="$(client_id stockroom-dashboard)"
if [ -z "$SYNC_ID" ] || [ "$SYNC_ID" = "None" ] || [ -z "$DASH_ID" ] || [ "$DASH_ID" = "None" ]; then
  echo "A client is missing. The job is configured with the existing client ID, so repair it in place."
  exit 1
fi
secret_of() {
  aws_local cognito-idp describe-user-pool-client --user-pool-id "$POOL_ID" --client-id "$1" \
    --query 'UserPoolClient.ClientSecret' --output text
}
SYNC_SECRET="$(secret_of "$SYNC_ID")"
DASH_SECRET="$(secret_of "$DASH_ID")"
if [ -z "$SYNC_SECRET" ] || [ "$SYNC_SECRET" = "None" ]; then
  echo "nightly-sync has no client secret any more; the job cannot authenticate without it."
  exit 1
fi

TOKEN_URL="$AWS_ENDPOINT_URL/cognito-idp/oauth2/token"
# request CLIENT_ID SECRET SCOPES -> JSON body from the token endpoint
request() {
  curl -s -X POST "$TOKEN_URL" -u "$1:$2" -d grant_type=client_credentials --data-urlencode "scope=$3"
}

body="$(request "$SYNC_ID" "$SYNC_SECRET" "inventory/read inventory/write")"
token="$(printf '%s' "$body" | jq -r '.access_token // empty' 2>/dev/null || true)"
if [ -z "$token" ]; then
  echo "The token endpoint still refuses nightly-sync: $(printf '%s' "$body" | jq -r '.error + ": " + .error_description' 2>/dev/null || printf '%s' "$body")"
  exit 1
fi
scopes="$(printf '%s' "$token" | python3 -c '
import sys, json, base64
part = sys.stdin.read().strip().split(".")[1]
part += "=" * (-len(part) % 4)
print(json.loads(base64.urlsafe_b64decode(part)).get("scope", ""))')"
for want in inventory/read inventory/write; do
  case " $scopes " in
    *" $want "*) ;;
    *) echo "The access token carries scope [$scopes], which lacks $want."; exit 1 ;;
  esac
done

body="$(request "$SYNC_ID" "$SYNC_SECRET" "inventory/admin")"
if [ -n "$(printf '%s' "$body" | jq -r '.access_token // empty' 2>/dev/null || true)" ]; then
  echo "nightly-sync can now obtain inventory/admin. A sync job must not be able to change warehouse configuration."
  exit 1
fi
if ! aws_local cognito-idp describe-resource-server --user-pool-id "$POOL_ID" --identifier inventory \
     --query 'ResourceServer.Scopes[].ScopeName' --output text | tr '\t' '\n' | grep -qx admin; then
  echo "The admin scope was removed from the inventory resource server. Other callers still depend on it; it must stay defined."
  exit 1
fi

body="$(request "$DASH_ID" "$DASH_SECRET" "inventory/write")"
if [ -n "$(printf '%s' "$body" | jq -r '.access_token // empty' 2>/dev/null || true)" ]; then
  echo "The read-only dashboard client can now obtain inventory/write. Only nightly-sync should get it."
  exit 1
fi
body="$(request "$DASH_ID" "$DASH_SECRET" "inventory/read")"
if [ -z "$(printf '%s' "$body" | jq -r '.access_token // empty' 2>/dev/null || true)" ]; then
  echo "The dashboard client lost its read access."
  exit 1
fi

echo "nightly-sync gets read and write, the dashboard still only reads, and admin is out of reach."
