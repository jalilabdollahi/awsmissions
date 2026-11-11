#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

POOL_ID="$(aws_local cognito-idp list-user-pools --max-results 60 \
  --query "UserPools[?Name=='fernwood-staff'].Id | [0]" --output text)"

aws_local iam put-user-policy --user-name fernwood-provisioner --policy-name onboarding \
  --policy-document "{
  \"Version\": \"2012-10-17\",
  \"Statement\": [
    {
      \"Sid\": \"OnboardNewHires\",
      \"Effect\": \"Allow\",
      \"Action\": [
        \"cognito-idp:AdminCreateUser\",
        \"cognito-idp:AdminGetUser\",
        \"cognito-idp:AdminSetUserPassword\",
        \"cognito-idp:AdminAddUserToGroup\"
      ],
      \"Resource\": \"arn:aws:cognito-idp:us-east-1:${ACCOUNT_ID}:userpool/${POOL_ID}\"
    }
  ]
}"
