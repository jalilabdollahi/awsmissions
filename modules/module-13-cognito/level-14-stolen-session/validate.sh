#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

POOL_ID="$(aws_local cognito-idp list-user-pools --max-results 60 \
  --query "UserPools[?Name=='halyard-crew'].Id | [0]" --output text 2>/dev/null || true)"
if [ -z "$POOL_ID" ] || [ "$POOL_ID" = "None" ]; then
  echo "The user pool halyard-crew no longer exists."
  exit 1
fi
CLIENT_ID="$(aws_local cognito-idp list-user-pool-clients --user-pool-id "$POOL_ID" --max-results 60 \
  --query "UserPoolClients[?ClientName=='halyard-app'].ClientId | [0]" --output text)"
if [ -z "$CLIENT_ID" ] || [ "$CLIENT_ID" = "None" ]; then
  echo "The client halyard-app no longer exists."
  exit 1
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
fetch() {  # fetch BUCKET KEY NAME
  aws_local s3 cp "s3://$1/$2" "$tmp/$3" >/dev/null 2>&1 || {
    echo "The session record s3://$1/$2 is missing; the exercise data must stay in place."
    exit 1
  }
}
fetch halyard-ir-evidence captured/laptop.json laptop.json
fetch halyard-ir-evidence captured/phone.json phone.json
fetch halyard-app-state session-cache/mara-0312.json unlogged.json
fetch halyard-app-state session-cache/noah-vessel.json noah.json

session_alive() {  # session_alive FILE -> "access" / "refresh" / "none"
  local at rt alive=""
  at="$(jq -r .access_token "$1")"
  rt="$(jq -r .refresh_token "$1")"
  if aws_local cognito-idp get-user --access-token "$at" >/dev/null 2>&1; then alive="access"; fi
  if aws_local cognito-idp initiate-auth --client-id "$CLIENT_ID" --auth-flow REFRESH_TOKEN_AUTH \
       --auth-parameters "REFRESH_TOKEN=$rt" >/dev/null 2>&1; then alive="${alive:+$alive+}refresh"; fi
  echo "${alive:-none}"
}

# 1. Mara's account must still be hers, and recoverable.
if ! status_line="$(aws_local cognito-idp admin-get-user --user-pool-id "$POOL_ID" --username mara \
      --query '[UserStatus, Enabled, UserAttributes[?Name==`sub`].Value | [0]]' --output text 2>/dev/null)"; then
  echo "Mara's account no longer exists. Deleting the victim is not incident response; she must be able to recover her account."
  exit 1
fi
mara_status="$(printf '%s' "$status_line" | awk '{print $1}')"
mara_enabled="$(printf '%s' "$status_line" | awk '{print $2}')"
mara_sub="$(printf '%s' "$status_line" | awk '{print $3}')"
original_sub="$(jq -r .access_token "$tmp/laptop.json" | python3 -c '
import sys, json, base64
part = sys.stdin.read().strip().split(".")[1]
part += "=" * (-len(part) % 4)
print(json.loads(base64.urlsafe_b64decode(part))["sub"])')"
if [ "$mara_sub" != "$original_sub" ]; then
  echo "Mara's account was deleted and recreated (her identity changed). Everything linked to her old identity is lost; repair the account in place."
  exit 1
fi
if [ "$mara_enabled" != "True" ] && [ "$mara_enabled" != "true" ]; then
  echo "Mara's account is disabled. She has to be able to get back in once she wakes up; lock the attacker out, not the owner."
  exit 1
fi
if [ "$mara_status" = "UNCONFIRMED" ] || [ "$mara_status" = "ARCHIVED" ]; then
  echo "Mara's account is in the status $mara_status and cannot be recovered."
  exit 1
fi

# 2. No attacker session may survive.
for name in laptop phone; do
  state="$(session_alive "$tmp/$name.json")"
  if [ "$state" != "none" ]; then
    echo "The captured $name session still works ($state). Both its access token and its refresh token must be dead."
    exit 1
  fi
done
state="$(session_alive "$tmp/unlogged.json")"
if [ "$state" != "none" ]; then
  echo "A session that is not in the evidence bucket still works ($state). You cannot revoke tokens you have never seen, so think about how to end every session of an account at once."
  exit 1
fi

# 3. The leaked password is worthless.
if aws_local cognito-idp initiate-auth --client-id "$CLIENT_ID" --auth-flow USER_PASSWORD_AUTH \
     --auth-parameters 'USERNAME=mara,PASSWORD=Anchor-Chain-0451!' >/dev/null 2>&1; then
  echo "The attacker can start a new session: Mara's leaked password still works."
  exit 1
fi

# 4. Noah is undisturbed.
noah_state="$(session_alive "$tmp/noah.json")"
if [ "$noah_state" != "access+refresh" ]; then
  echo "Noah's existing session was cut (still working: $noah_state). Only Mara's sessions were compromised."
  exit 1
fi
if ! aws_local cognito-idp initiate-auth --client-id "$CLIENT_ID" --auth-flow USER_PASSWORD_AUTH \
     --auth-parameters 'USERNAME=noah,PASSWORD=Starboard-Light-77!' >/dev/null 2>&1; then
  echo "Noah can no longer sign in with his own password."
  exit 1
fi

echo "All of the attacker's sessions are dead, the leaked password is useless, Mara can recover, and Noah never noticed."
