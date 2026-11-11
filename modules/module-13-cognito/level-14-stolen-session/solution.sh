#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

pool="$(aws_local cognito-idp list-user-pools --max-results 60 \
  --query "UserPools[?Name=='halyard-crew'].Id | [0]" --output text)"

# Step 1: look at the evidence the security team captured.
aws_local s3 ls s3://halyard-ir-evidence/ --recursive

# Step 2: kill every session of the account, including the ones nobody has captured.
echo "Signing mara out everywhere..."
aws_local cognito-idp admin-user-global-sign-out --user-pool-id "$pool" --username mara

# Step 3: the leaked password must stop working. Mara picks a new one later via forgot-password.
echo "Forcing a password reset for mara..."
aws_local cognito-idp admin-reset-user-password --user-pool-id "$pool" --username mara
