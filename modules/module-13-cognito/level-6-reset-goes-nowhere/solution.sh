#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

POOL_ID="$(aws_local cognito-idp list-user-pools --max-results 60 \
  --query "UserPools[?Name=='pinecrest-patrons'].Id | [0]" --output text)"

# Correct the address and mark it verified in the same call.
aws_local cognito-idp admin-update-user-attributes --user-pool-id "$POOL_ID" --username omar \
  --user-attributes Name=email,Value=omar@example.com Name=email_verified,Value=true
