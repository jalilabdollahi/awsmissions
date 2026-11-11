#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# The pool as it was before the migration. It is deleted again, but the policy still names it.
OLD_POOL_ID="$(aws_local cognito-idp create-user-pool --pool-name fernwood-staff-legacy \
  --query 'UserPool.Id' --output text)"
aws_local cognito-idp delete-user-pool --user-pool-id "$OLD_POOL_ID"

POOL_ID="$(aws_local cognito-idp create-user-pool --pool-name fernwood-staff \
  --query 'UserPool.Id' --output text)"
aws_local cognito-idp create-group --user-pool-id "$POOL_ID" --group-name employees >/dev/null

CONTRACTORS_ID="$(aws_local cognito-idp create-user-pool --pool-name fernwood-contractors \
  --query 'UserPool.Id' --output text)"
aws_local cognito-idp create-group --user-pool-id "$CONTRACTORS_ID" --group-name vendors >/dev/null

aws_local iam create-user --user-name fernwood-provisioner >/dev/null
aws_local iam put-user-policy --user-name fernwood-provisioner --policy-name onboarding \
  --policy-document "{
  \"Version\": \"2012-10-17\",
  \"Statement\": [
    {
      \"Sid\": \"OnboardNewHires\",
      \"Effect\": \"Allow\",
      \"Action\": [\"cognito-idp:AdminCreateUser\", \"cognito-idp:AdminGetUser\"],
      \"Resource\": \"arn:aws:cognito-idp:us-east-1:${ACCOUNT_ID}:userpool/${OLD_POOL_ID}\"
    }
  ]
}"

echo "fernwood-provisioner holds a policy written for the pool as it was before the migration."
