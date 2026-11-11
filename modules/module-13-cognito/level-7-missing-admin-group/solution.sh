#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

POOL_ID="$(aws_local cognito-idp list-user-pools --max-results 60 \
  --query "UserPools[?Name=='parcelpost-staff'].Id | [0]" --output text)"

aws_local cognito-idp create-group --user-pool-id "$POOL_ID" --group-name ops-admins \
  --description "Operations leads" --precedence 1 >/dev/null
aws_local cognito-idp admin-add-user-to-group --user-pool-id "$POOL_ID" --username dara --group-name ops-admins
