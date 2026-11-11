#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

POOL_ID="$(aws_local cognito-idp list-user-pools --max-results 60 \
  --query "UserPools[?Name=='tidewater-readers'].Id | [0]" --output text 2>/dev/null || true)"
if [ -z "$POOL_ID" ] || [ "$POOL_ID" = "None" ]; then
  echo "The user pool tidewater-readers no longer exists."
  exit 1
fi
CLIENT_ID="$(aws_local cognito-idp list-user-pool-clients --user-pool-id "$POOL_ID" --max-results 60 \
  --query "UserPoolClients[?ClientName=='tidewater-web'].ClientId | [0]" --output text)"
if [ -z "$CLIENT_ID" ] || [ "$CLIENT_ID" = "None" ]; then
  echo "The app client tidewater-web no longer exists."
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

# try_signup LABEL PASSWORD -> prints "ok" or the exception name
try_signup() {
  local user="reader-$1-$stamp" out rc
  set +e
  out="$(aws_local cognito-idp sign-up --client-id "$CLIENT_ID" --username "$user" --password "$2" \
    --user-attributes "Name=email,Value=$user@example.com" 2>&1)"
  rc=$?
  set -e
  if [ "$rc" -eq 0 ]; then
    created="$created $user"
    echo ok
  else
    printf '%s' "$out" | grep -o '[A-Za-z]*Exception' | head -1
  fi
}

res="$(try_signup good 'Tidewater42Books')"
if [ "$res" != "ok" ]; then
  echo "A reader still cannot sign up with Tidewater42Books (result: $res)."
  echo "Look at what the pool demands of a password, and compare it with the agreed rule."
  exit 1
fi

res="$(try_signup short 'Tide42Bk')"
if [ "$res" = "ok" ]; then
  echo "An 8-character password was accepted. The agreed minimum length is 10."
  exit 1
fi
res="$(try_signup nodigit 'TidewaterBooksAA')"
if [ "$res" = "ok" ]; then
  echo "A password with no digit was accepted. The rule still requires a number."
  exit 1
fi
res="$(try_signup noupper 'tidewaterbooks42')"
if [ "$res" = "ok" ]; then
  echo "A password with no upper-case letter was accepted. The rule still requires one."
  exit 1
fi
res="$(try_signup nolower 'TIDEWATERBOOKS42')"
if [ "$res" = "ok" ]; then
  echo "A password with no lower-case letter was accepted. The rule still requires one."
  exit 1
fi

echo "Readers can register with sensible passwords again, and weak ones are still turned away."
