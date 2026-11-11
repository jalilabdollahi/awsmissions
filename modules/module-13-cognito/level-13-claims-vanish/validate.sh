#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

POOL_ID="$(aws_local cognito-idp list-user-pools --max-results 60 \
  --query "UserPools[?Name=='cobalt-tenants'].Id | [0]" --output text 2>/dev/null || true)"
if [ -z "$POOL_ID" ] || [ "$POOL_ID" = "None" ]; then
  echo "The user pool cobalt-tenants no longer exists."
  exit 1
fi
CLIENT_ID="$(aws_local cognito-idp list-user-pool-clients --user-pool-id "$POOL_ID" --max-results 60 \
  --query "UserPoolClients[?ClientName=='cobalt-app'].ClientId | [0]" --output text)"
if [ -z "$CLIENT_ID" ] || [ "$CLIENT_ID" = "None" ]; then
  echo "The client cobalt-app no longer exists."
  exit 1
fi

tenant_of() {  # tenant_of USER -> the tenant claim of a fresh ID token, or NOSIGNIN
  local tok
  if ! tok="$(aws_local cognito-idp initiate-auth --client-id "$CLIENT_ID" --auth-flow USER_PASSWORD_AUTH \
        --auth-parameters "USERNAME=$1,PASSWORD=Tenant-Wall-2024!" \
        --query 'AuthenticationResult.IdToken' --output text 2>/dev/null)"; then
    echo NOSIGNIN
    return 0
  fi
  printf '%s' "$tok" | python3 -c '
import sys, json, base64
part = sys.stdin.read().strip().split(".")[1]
part += "=" * (-len(part) % 4)
print(json.loads(base64.urlsafe_b64decode(part)).get("tenant", "MISSING"))'
}

ava="$(tenant_of ava)"
ben="$(tenant_of ben)"
if [ "$ava" = "NOSIGNIN" ] || [ "$ben" = "NOSIGNIN" ]; then
  echo "A user cannot sign in at all any more. Do not touch the accounts."
  exit 1
fi

post="$(aws_local cognito-idp describe-user-pool --user-pool-id "$POOL_ID" \
  --query 'UserPool.LambdaConfig.PostConfirmation' --output text)"
pre="$(aws_local cognito-idp describe-user-pool --user-pool-id "$POOL_ID" \
  --query 'UserPool.LambdaConfig.PreTokenGeneration' --output text)"

if [ "$ava" = "MISSING" ] && [ "$ben" = "MISSING" ]; then
  if [ -z "$pre" ] || [ "$pre" = "None" ]; then
    echo "Fresh ID tokens carry no tenant claim, and the pool has no pre token generation trigger at all right now."
  else
    echo "The pool calls a pre token generation trigger, but the ID tokens still carry no tenant claim."
    echo "Check what the function actually receives and what it returns."
  fi
  exit 1
fi
if [ "$ava" != "acme" ]; then
  echo "Ava's ID token has tenant=$ava; it must be acme."
  exit 1
fi
if [ "$ben" != "globex" ]; then
  echo "Ben's ID token has tenant=$ben; it must be globex."
  exit 1
fi

if ! printf '%s' "$post" | grep -q 'cobalt-welcome'; then
  echo "The tenant claim is back, but the cobalt-welcome post confirmation trigger is no longer attached. New customers would get no welcome email."
  exit 1
fi
if ! printf '%s' "$pre" | grep -q 'cobalt-claims'; then
  echo "The claim is present but the pool does not reference cobalt-claims."
  exit 1
fi

minlen="$(aws_local cognito-idp describe-user-pool --user-pool-id "$POOL_ID" \
  --query 'UserPool.Policies.PasswordPolicy.MinimumLength' --output text)"
if [ "$minlen" != "10" ]; then
  echo "The pool's password policy changed (minimum length $minlen). Only the trigger configuration was supposed to change."
  exit 1
fi

echo "Both tenants get their claim again and the welcome trigger is still attached."
