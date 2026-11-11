#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

POOL_ID="$(aws_local cognito-idp create-user-pool --pool-name halyard-crew \
  --query 'UserPool.Id' --output text)"
CLIENT_ID="$(aws_local cognito-idp create-user-pool-client --user-pool-id "$POOL_ID" \
  --client-name halyard-app \
  --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH \
  --query 'UserPoolClient.ClientId' --output text)"

for pair in mara:'Anchor-Chain-0451!' noah:'Starboard-Light-77!'; do
  who="${pair%%:*}"
  pw="${pair#*:}"
  aws_local cognito-idp admin-create-user --user-pool-id "$POOL_ID" --username "$who" \
    --message-action SUPPRESS --user-attributes "Name=email,Value=$who@example.com" >/dev/null
  aws_local cognito-idp admin-set-user-password --user-pool-id "$POOL_ID" --username "$who" \
    --password "$pw" --permanent
done

aws_local s3 mb s3://halyard-ir-evidence >/dev/null
aws_local s3 mb s3://halyard-app-state >/dev/null

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# capture USER PASSWORD LABEL BUCKET KEY : sign in and store the resulting session as JSON.
capture() {
  aws_local cognito-idp initiate-auth --client-id "$CLIENT_ID" --auth-flow USER_PASSWORD_AUTH \
    --auth-parameters "USERNAME=$1,PASSWORD=$2" --output json \
    | jq --arg user "$1" --arg label "$3" --arg client "$CLIENT_ID" \
        '{user: $user, session: $label, client_id: $client,
          access_token: .AuthenticationResult.AccessToken,
          refresh_token: .AuthenticationResult.RefreshToken}' > "$tmp/session.json"
  aws_local s3 cp "$tmp/session.json" "s3://$4/$5" >/dev/null
}

# What the security team captured.
capture mara 'Anchor-Chain-0451!' "attacker laptop" halyard-ir-evidence captured/laptop.json
capture mara 'Anchor-Chain-0451!' "attacker phone" halyard-ir-evidence captured/phone.json
# A session nobody has seen (the app keeps its own server-side session cache).
capture mara 'Anchor-Chain-0451!' "attacker unlogged" halyard-app-state session-cache/mara-0312.json
# Noah's legitimate session on the vessel.
capture noah 'Starboard-Light-77!' "noah vessel" halyard-app-state session-cache/noah-vessel.json

echo "halyard-crew is live. Mara's account is being used by someone else."
