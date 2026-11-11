#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

POOL_ID="$(aws_local cognito-idp list-user-pools --max-results 60 \
  --query "UserPools[?Name=='brightpath-partners'].Id | [0]" --output text 2>/dev/null || true)"
if [ -z "$POOL_ID" ] || [ "$POOL_ID" = "None" ]; then
  echo "The user pool brightpath-partners no longer exists."
  exit 1
fi
CLIENT_ID="$(aws_local cognito-idp list-user-pool-clients --user-pool-id "$POOL_ID" --max-results 60 \
  --query "UserPoolClients[?ClientName=='brightpath-portal'].ClientId | [0]" --output text)"
if [ -z "$CLIENT_ID" ] || [ "$CLIENT_ID" = "None" ]; then
  echo "The client brightpath-portal no longer exists."
  exit 1
fi
trigger="$(aws_local cognito-idp describe-user-pool --user-pool-id "$POOL_ID" \
  --query 'UserPool.LambdaConfig.PreSignUp' --output text)"
if [ -z "$trigger" ] || [ "$trigger" = "None" ] || ! printf '%s' "$trigger" | grep -q 'brightpath-presignup'; then
  echo "The pre sign-up trigger is no longer attached to the pool. The fix belongs in the function, not in removing it."
  exit 1
fi

stamp="$(date +%s)"
created=""
cleanup() {
  for u in $created; do
    aws_local cognito-idp admin-delete-user --user-pool-id "$POOL_ID" --username "$u" >/dev/null 2>&1 || true
  done
}
trap cleanup EXIT

signup() {  # signup USERNAME EMAIL -> prints JSON or the error text
  local out
  if out="$(aws_local cognito-idp sign-up --client-id "$CLIENT_ID" --username "$1" \
      --password 'Onboard-Me-2024!' --user-attributes "Name=email,Value=$2" --output json 2>&1)"; then
    created="$created $1"
    printf '%s' "$out"
  else
    printf 'ERROR %s' "$(printf '%s' "$out" | tail -1)"
  fi
}

# 1. Partner, lower-case address.
res="$(signup "p1-$stamp" "dev$stamp@partner.example.com")"
case "$res" in
  ERROR*) echo "A partner sign-up fails: ${res#ERROR }"; exit 1 ;;
esac
if [ "$(printf '%s' "$res" | jq -r '.UserConfirmed')" != "true" ]; then
  echo "A partner sign-up succeeds but the account is not confirmed."
  exit 1
fi

# 2. Partner, mixed-case address and the second partner domain.
res="$(signup "p2-$stamp" "Dev$stamp@Partner.Example.COM")"
case "$res" in
  ERROR*) echo "A partner sign-up with capital letters in the address fails: ${res#ERROR }"; exit 1 ;;
esac
if [ "$(printf '%s' "$res" | jq -r '.UserConfirmed')" != "true" ]; then
  echo "A partner address typed with capital letters is not confirmed. Email domains are case-insensitive."
  exit 1
fi
res="$(signup "p3-$stamp" "ops$stamp@agency.example.org")"
case "$res" in
  ERROR*) echo "A sign-up from agency.example.org fails: ${res#ERROR }"; exit 1 ;;
esac

# The result must be a really usable account.
verified="$(aws_local cognito-idp admin-get-user --user-pool-id "$POOL_ID" --username "p1-$stamp" \
  --query "UserAttributes[?Name=='email_verified'].Value | [0]" --output text)"
if [ "$verified" != "true" ]; then
  echo "The partner account is confirmed but its email is not marked as verified."
  exit 1
fi
if ! aws_local cognito-idp initiate-auth --client-id "$CLIENT_ID" --auth-flow USER_PASSWORD_AUTH \
     --auth-parameters "USERNAME=p1-$stamp,PASSWORD=Onboard-Me-2024!" --query 'AuthenticationResult.IdToken' \
     --output text >/dev/null 2>&1; then
  echo "The auto-confirmed partner cannot sign in."
  exit 1
fi

# 3. Everybody else keeps the normal flow.
res="$(signup "o1-$stamp" "someone$stamp@gmail.example.net")"
case "$res" in
  ERROR*) echo "A sign-up from an ordinary domain now fails: ${res#ERROR }"; exit 1 ;;
esac
if [ "$(printf '%s' "$res" | jq -r '.UserConfirmed')" = "true" ]; then
  echo "A sign-up from a non-partner domain was confirmed automatically. Only partner domains skip the email code."
  exit 1
fi
res="$(signup "o2-$stamp" "mallory$stamp@partner.example.com.evil.example.net")"
case "$res" in
  ERROR*) echo "A lookalike-domain sign-up fails: ${res#ERROR }"; exit 1 ;;
esac
if [ "$(printf '%s' "$res" | jq -r '.UserConfirmed')" = "true" ]; then
  echo "A lookalike domain (partner.example.com.evil.example.net) was auto-confirmed. Compare whole domains, not prefixes."
  exit 1
fi

echo "Partner sign-ups confirm instantly (any capitalisation), everyone else still needs the email code."
