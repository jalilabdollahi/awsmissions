#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

KEY="$(aws_local kms describe-key --key-id alias/vl-patient-notes --query KeyMetadata.KeyId --output text)"

# 1. Rescue the key: cancel the deletion, then enable it again (cancel leaves it Disabled), and turn on rotation.
aws_local kms cancel-key-deletion --key-id "$KEY" >/dev/null
aws_local kms enable-key --key-id "$KEY"
aws_local kms enable-key-rotation --key-id "$KEY"

# 2. Point the function at the real alias.
aws_local lambda update-function-configuration --function-name vl-note-reader \
  --environment 'Variables={KEY_ALIAS=alias/vl-patient-notes}' >/dev/null
aws_local lambda wait function-updated-v2 --function-name vl-note-reader 2>/dev/null || sleep 2

# 3. Role policy: decrypt and encrypt on the patient-notes key only.
aws_local iam put-role-policy --role-name vl-reader-role --policy-name reader --policy-document "{
  \"Version\":\"2012-10-17\",\"Statement\":[
   {\"Sid\":\"Vault\",\"Effect\":\"Allow\",\"Action\":\"dynamodb:GetItem\",\"Resource\":\"arn:aws:dynamodb:us-east-1:000000000000:table/vl-vault\"},
   {\"Sid\":\"Kms\",\"Effect\":\"Allow\",\"Action\":[\"kms:Decrypt\",\"kms:Encrypt\"],\"Resource\":\"arn:aws:kms:us-east-1:000000000000:key/$KEY\"}]}"
