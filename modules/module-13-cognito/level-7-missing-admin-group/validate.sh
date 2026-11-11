#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

POOL_ID="$(aws_local cognito-idp list-user-pools --max-results 60 \
  --query "UserPools[?Name=='parcelpost-staff'].Id | [0]" --output text 2>/dev/null || true)"
if [ -z "$POOL_ID" ] || [ "$POOL_ID" = "None" ]; then
  echo "The user pool parcelpost-staff no longer exists."
  exit 1
fi
CLIENT_ID="$(aws_local cognito-idp list-user-pool-clients --user-pool-id "$POOL_ID" --max-results 60 \
  --query "UserPoolClients[?ClientName=='parcelpost-console'].ClientId | [0]" --output text)"
if [ -z "$CLIENT_ID" ] || [ "$CLIENT_ID" = "None" ]; then
  echo "The app client parcelpost-console no longer exists."
  exit 1
fi

# groups_of USER -> space separated groups from a freshly issued ID token
groups_of() {
  local out
  if ! out="$(aws_local cognito-idp initiate-auth --client-id "$CLIENT_ID" --auth-flow USER_PASSWORD_AUTH \
        --auth-parameters "USERNAME=$1,PASSWORD=Parcel-Route-2024!" --query 'AuthenticationResult.IdToken' \
        --output text 2>&1)"; then
    echo "SIGNIN_FAILED"
    return 0
  fi
  printf '%s' "$out" | python3 -c '
import sys, json, base64
part = sys.stdin.read().strip().split(".")[1]
part += "=" * (-len(part) % 4)
print(" ".join(json.loads(base64.urlsafe_b64decode(part)).get("cognito:groups", [])))'
}

dara_groups="$(groups_of dara)"
eli_groups="$(groups_of eli)"
if [ "$dara_groups" = "SIGNIN_FAILED" ] || [ "$eli_groups" = "SIGNIN_FAILED" ]; then
  echo "A sign-in failed entirely; the users and their passwords must stay as they are."
  exit 1
fi

case " $dara_groups " in
  *" ops-admins "*) ;;
  *)
    echo "Dara's ID token has these groups: [${dara_groups:-none}]. The console is waiting for ops-admins."
    exit 1 ;;
esac
case " $eli_groups " in
  *" ops-admins "*)
    echo "Eli now has the ops-admins group. Support staff must stay read-only."
    exit 1 ;;
esac
case " $eli_groups " in
  *" support "*) ;;
  *)
    echo "Eli lost his support group (his groups: [${eli_groups:-none}]). Only Dara's access needed changing."
    exit 1 ;;
esac

echo "Dara's token carries ops-admins, Eli's does not. The console shows the right screens."
