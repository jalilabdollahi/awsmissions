#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

NEW_ARN="$(aws_local secretsmanager describe-secret --secret-id juniper/prod/db-credentials --query ARN --output text)"

# 1. Let the role read the re-created secret (name-based ARN with the suffix wildcard).
aws_local iam put-role-policy --role-name juniper-claims-role --policy-name claims-secrets --policy-document '{
  "Version":"2012-10-17","Statement":[
   {"Sid":"ReadDbSecret","Effect":"Allow","Action":"secretsmanager:GetSecretValue","Resource":"arn:aws:secretsmanager:us-east-1:000000000000:secret:juniper/prod/db-credentials-*"},
   {"Sid":"ReadLiveMirror","Effect":"Allow","Action":"ssm:GetParameter","Resource":"arn:aws:ssm:us-east-1:000000000000:parameter/juniper/db/live-password"}]}'

# 2. Point the function at the live secret.
aws_local lambda update-function-configuration --function-name juniper-claims-api \
  --environment "Variables={SECRET_ID=$NEW_ARN}" >/dev/null
aws_local lambda wait function-updated-v2 --function-name juniper-claims-api 2>/dev/null || sleep 2

# 3. Promote the pending version (the new password) to AWSCURRENT.
PENDING="$(aws_local secretsmanager describe-secret --secret-id juniper/prod/db-credentials --output json \
  | jq -r '.VersionIdsToStages | to_entries[] | select(.value | index("AWSPENDING")) | .key')"
CURRENT="$(aws_local secretsmanager describe-secret --secret-id juniper/prod/db-credentials --output json \
  | jq -r '.VersionIdsToStages | to_entries[] | select(.value | index("AWSCURRENT")) | .key')"
aws_local secretsmanager update-secret-version-stage --secret-id juniper/prod/db-credentials \
  --version-stage AWSCURRENT --move-to-version-id "$PENDING" --remove-from-version-id "$CURRENT"
