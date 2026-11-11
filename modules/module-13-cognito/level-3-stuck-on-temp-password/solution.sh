#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

POOL_ID="$(aws_local cognito-idp list-user-pools --max-results 60 \
  --query "UserPools[?Name=='lumen-dispatch'].Id | [0]" --output text)"

aws_local cognito-idp admin-set-user-password --user-pool-id "$POOL_ID" --username ines \
  --password 'Harbor-Crane-81x' --permanent
